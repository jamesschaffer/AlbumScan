import Foundation

// MARK: - MusicBrainz Response Models

struct MusicBrainzSearchResponse: Codable {
    let releases: [MusicBrainzRelease]
    let count: Int
}

struct MusicBrainzRelease: Codable {
    let id: String // Release MBID
    let title: String
    let artistCredit: [ArtistCredit]?
    let date: String?
    let country: String?
    let releaseGroup: ReleaseGroup? // NEW: Release group for better artwork

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case artistCredit = "artist-credit"
        case date
        case country
        case releaseGroup = "release-group"
    }
}

struct ReleaseGroup: Codable {
    let id: String // Release-group MBID (preferred for artwork)
    let title: String?
}

struct ArtistCredit: Codable {
    let name: String
    let artist: Artist?
}

struct Artist: Codable {
    let name: String
}

// MARK: - MusicBrainz Service

class MusicBrainzService {
    static let shared = MusicBrainzService()

    private let baseURL = "https://musicbrainz.org/ws/2"
    private let userAgent = "AlbumScan/1.0 (james@jamesschaffer.com)"

    private init() {}

    /// Search for an album and return the MusicBrainz ID (MBID)
    /// Tries multiple candidates until one with artwork is found
    func searchAlbum(artist: String, album: String) async throws -> String? {
        print("🔍 [MusicBrainz] Searching for: \(artist) - \(album)")

        // Add small delay to respect rate limiting (1 request per second)
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay

        // Construct search query
        let query = "artist:\(artist) AND release:\(album)"

        guard var components = URLComponents(string: "\(baseURL)/release") else {
            throw MusicBrainzError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "fmt", value: "json"),
            URLQueryItem(name: "limit", value: "10")  // Increased from 5 to 10 for more candidates
        ]

        guard let url = components.url else {
            throw MusicBrainzError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10.0 // Increased from 5 to 10 seconds

        print("🔍 [MusicBrainz] Request URL: \(url.absoluteString)")

        // Retry logic - try up to 2 times on network errors
        var lastError: Error?
        for attempt in 1...2 {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw MusicBrainzError.invalidResponse
                }

                print("🔍 [MusicBrainz] Response status: \(httpResponse.statusCode)")

                guard httpResponse.statusCode == 200 else {
                    if httpResponse.statusCode == 503 && attempt < 2 {
                        // Service unavailable, wait and retry
                        print("⚠️ [MusicBrainz] Service unavailable (503), retrying in 2 seconds...")
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        continue
                    }
                    throw MusicBrainzError.httpError(httpResponse.statusCode)
                }

                // Success! Parse response
                let searchResponse = try JSONDecoder().decode(MusicBrainzSearchResponse.self, from: data)
                print("🔍 [MusicBrainz] Found \(searchResponse.count) results")

                // Find the best match - try multiple candidates until we find one with artwork
                return await findBestMatchWithArtwork(in: searchResponse.releases, searchArtist: artist, searchAlbum: album)

            } catch let error as NSError where error.domain == NSURLErrorDomain {
                // Network error - retry once
                lastError = error
                if attempt < 2 {
                    print("⚠️ [MusicBrainz] Network error (attempt \(attempt)/2): \(error.code) - retrying...")
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // Wait 1 second before retry
                    continue
                } else {
                    print("❌ [MusicBrainz] Network error after 2 attempts")
                    throw error
                }
            }
        }

        // If we get here, all retries failed
        if let error = lastError {
            throw error
        }

        return nil
    }

    /// Find the best matching release that has artwork available
    /// Tries multiple candidates until one with artwork is found
    private func findBestMatchWithArtwork(in releases: [MusicBrainzRelease], searchArtist: String, searchAlbum: String) async -> String? {
        // Get sorted candidates using existing logic
        let sortedCandidates = getSortedCandidates(in: releases, searchArtist: searchArtist, searchAlbum: searchAlbum)

        if sortedCandidates.isEmpty {
            print("❌ [MusicBrainz] No matching results")
            return nil
        }

        print("🔍 [MusicBrainz] Trying \(min(sortedCandidates.count, 5)) candidates for artwork...")

        // Try up to 5 candidates to find one with artwork
        for (index, release) in sortedCandidates.prefix(5).enumerated() {
            let rgMbid = release.releaseGroup?.id
            print("🔍 [MusicBrainz] Candidate \(index + 1): release=\(release.id), release-group=\(rgMbid ?? "none") (country: \(release.country ?? "unknown"), date: \(release.date ?? "unknown"))")

            // Check if this release (or its release-group) has artwork
            if await hasArtwork(releaseMbid: release.id, releaseGroupMbid: rgMbid) {
                // Return release-group MBID if available (preferred), otherwise release MBID
                let preferredMbid = rgMbid ?? release.id
                print("✅ [MusicBrainz] Found MBID with artwork: \(preferredMbid) (type: \(rgMbid != nil ? "release-group" : "release"))")
                return preferredMbid
            }
        }

        // If no candidate has artwork, return the first one anyway as fallback
        if let firstCandidate = sortedCandidates.first {
            let fallbackMbid = firstCandidate.releaseGroup?.id ?? firstCandidate.id
            print("⚠️ [MusicBrainz] No candidates have artwork, using first result: \(fallbackMbid)")
            return fallbackMbid
        }

        return nil
    }

    /// Check if artwork exists, preferring release-group over release
    /// Uses fast HEAD requests for quick checks
    private func hasArtwork(releaseMbid: String, releaseGroupMbid: String?) async -> Bool {
        // Strategy: Try release-group first (community-chosen representative cover)
        // then fall back to release-level artwork

        // Priority 1: Try release-group/front (most popular/representative)
        if let rgMbid = releaseGroupMbid {
            if await checkArtworkExists(type: "release-group", mbid: rgMbid) {
                return true
            }
        }

        // Priority 2: Fall back to release/front
        return await checkArtworkExists(type: "release", mbid: releaseMbid)
    }

    /// Quick HEAD request to check if artwork exists
    private func checkArtworkExists(type: String, mbid: String) async -> Bool {
        guard let url = URL(string: "https://coverartarchive.org/\(type)/\(mbid)/front") else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"  // HEAD is faster than GET
        request.timeoutInterval = 3.0

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200 || httpResponse.statusCode == 307 // 307 = redirect to image
            }
            return false
        } catch {
            return false
        }
    }

    /// Get sorted candidates using existing matching logic (extracted for reuse)
    private func getSortedCandidates(in releases: [MusicBrainzRelease], searchArtist: String, searchAlbum: String) -> [MusicBrainzRelease] {
        // Filter releases that match the artist name
        let matchingReleases = releases.filter { release in
            guard let artistCredit = release.artistCredit?.first else { return false }
            let releaseArtist = artistCredit.name.lowercased()
            let searchArtistLower = searchArtist.lowercased()
            return releaseArtist.contains(searchArtistLower) || searchArtistLower.contains(releaseArtist)
        }

        // Sort to get consistent, high-quality results:
        // 1. Prefer releases from major markets (US, GB, XW=worldwide)
        // 2. Prefer earlier releases (original over reissues)
        let sortedReleases = matchingReleases.sorted { release1, release2 in
            // Priority 1: Prefer US, GB, or XW (worldwide) releases
            let preferredCountries = ["US", "GB", "XW"]
            let country1Priority = preferredCountries.contains(release1.country ?? "") ? 0 : 1
            let country2Priority = preferredCountries.contains(release2.country ?? "") ? 0 : 1

            if country1Priority != country2Priority {
                return country1Priority < country2Priority
            }

            // Priority 2: Prefer earlier release dates (original release)
            if let date1 = release1.date, let date2 = release2.date {
                return date1 < date2
            }

            // Priority 3: If one has a date and the other doesn't, prefer the one with a date
            if release1.date != nil && release2.date == nil {
                return true
            }
            if release1.date == nil && release2.date != nil {
                return false
            }

            // Otherwise maintain original order
            return false
        }

        // Return sorted candidates (if no exact matches, return all releases sorted)
        return sortedReleases.isEmpty ? releases : sortedReleases
    }

}

// MARK: - Errors

enum MusicBrainzError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case noResults

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid MusicBrainz URL"
        case .invalidResponse:
            return "Invalid response from MusicBrainz"
        case .httpError(let code):
            return "MusicBrainz HTTP error: \(code)"
        case .noResults:
            return "No results found on MusicBrainz"
        }
    }
}
