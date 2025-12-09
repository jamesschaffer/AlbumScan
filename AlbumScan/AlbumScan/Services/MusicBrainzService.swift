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

// MARK: - Release Group Relations Response Models

struct ReleaseGroupRelationsResponse: Codable {
    let id: String
    let title: String?
    let relations: [Relation]?
}

struct Relation: Codable {
    let type: String
    let url: RelationURL?
    let releaseGroup: RelatedReleaseGroup?

    enum CodingKeys: String, CodingKey {
        case type
        case url
        case releaseGroup = "release_group"  // Note: underscore, not hyphen
    }
}

struct RelationURL: Codable {
    let resource: String
}

struct RelatedReleaseGroup: Codable {
    let title: String
    let firstReleaseDate: String?

    enum CodingKeys: String, CodingKey {
        case title
        case firstReleaseDate = "first-release-date"
    }
}

/// Result from fetching release-group relations
struct ReleaseGroupRelationsResult {
    let singles: [String]
    let reviewURLs: [String]
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
        #if DEBUG
        print("🔍 [MusicBrainz] Searching for: \(artist) - \(album)")
        #endif

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

        #if DEBUG
        print("🔍 [MusicBrainz] Request URL: \(url.absoluteString)")
        #endif

        // Retry logic - try up to 2 times on network errors
        var lastError: Error?
        for attempt in 1...2 {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw MusicBrainzError.invalidResponse
                }

                #if DEBUG
                print("🔍 [MusicBrainz] Response status: \(httpResponse.statusCode)")
                #endif

                guard httpResponse.statusCode == 200 else {
                    if httpResponse.statusCode == 503 && attempt < 2 {
                        // Service unavailable, wait and retry
                        #if DEBUG
                        print("⚠️ [MusicBrainz] Service unavailable (503), retrying in 2 seconds...")
                        #endif
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        continue
                    }
                    throw MusicBrainzError.httpError(httpResponse.statusCode)
                }

                // Success! Parse response
                let searchResponse = try JSONDecoder().decode(MusicBrainzSearchResponse.self, from: data)
                #if DEBUG
                print("🔍 [MusicBrainz] Found \(searchResponse.count) results")
                #endif

                // Find the best match - try multiple candidates until we find one with artwork
                return await findBestMatchWithArtwork(in: searchResponse.releases, searchArtist: artist, searchAlbum: album)

            } catch let error as NSError where error.domain == NSURLErrorDomain {
                // Network error - retry once
                lastError = error
                if attempt < 2 {
                    #if DEBUG
                    print("⚠️ [MusicBrainz] Network error (attempt \(attempt)/2): \(error.code) - retrying...")
                    #endif
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // Wait 1 second before retry
                    continue
                } else {
                    #if DEBUG
                    print("❌ [MusicBrainz] Network error after 2 attempts")
                    #endif
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
            #if DEBUG
            print("❌ [MusicBrainz] No matching results")
            #endif
            return nil
        }

        #if DEBUG
        print("🔍 [MusicBrainz] Trying \(min(sortedCandidates.count, 5)) candidates for artwork...")
        #endif

        // Try up to 5 candidates to find one with artwork
        for (index, release) in sortedCandidates.prefix(5).enumerated() {
            let rgMbid = release.releaseGroup?.id
            #if DEBUG
            print("🔍 [MusicBrainz] Candidate \(index + 1): release=\(release.id), release-group=\(rgMbid ?? "none") (country: \(release.country ?? "unknown"), date: \(release.date ?? "unknown"))")
            #endif

            // Check if this release (or its release-group) has artwork
            if await hasArtwork(releaseMbid: release.id, releaseGroupMbid: rgMbid) {
                // Return release-group MBID if available (preferred), otherwise release MBID
                let preferredMbid = rgMbid ?? release.id
                #if DEBUG
                print("✅ [MusicBrainz] Found MBID with artwork: \(preferredMbid) (type: \(rgMbid != nil ? "release-group" : "release"))")
                #endif
                return preferredMbid
            }
        }

        // If no candidate has artwork, return the first one anyway as fallback
        if let firstCandidate = sortedCandidates.first {
            let fallbackMbid = firstCandidate.releaseGroup?.id ?? firstCandidate.id
            #if DEBUG
            print("⚠️ [MusicBrainz] No candidates have artwork, using first result: \(fallbackMbid)")
            #endif
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

    // MARK: - Release Group Relations

    /// Fetch singles and review URLs for a release-group
    /// This is a separate call that can run in parallel with other operations
    func fetchReleaseGroupRelations(mbid: String) async throws -> ReleaseGroupRelationsResult {
        #if DEBUG
        print("🔗 [MusicBrainz] Fetching relations for release-group: \(mbid)")
        #endif

        // Construct URL: /ws/2/release-group/<MBID>?inc=release-group-rels+url-rels&fmt=json
        guard var components = URLComponents(string: "\(baseURL)/release-group/\(mbid)") else {
            throw MusicBrainzError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "inc", value: "release-group-rels+url-rels"),
            URLQueryItem(name: "fmt", value: "json")
        ]

        guard let url = components.url else {
            throw MusicBrainzError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10.0

        #if DEBUG
        print("🔗 [MusicBrainz] Relations URL: \(url.absoluteString)")
        #endif

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MusicBrainzError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw MusicBrainzError.httpError(httpResponse.statusCode)
        }

        let relationsResponse = try JSONDecoder().decode(ReleaseGroupRelationsResponse.self, from: data)

        // Extract singles (type == "single from")
        var singles: [String] = []
        if let relations = relationsResponse.relations {
            singles = relations
                .filter { $0.type == "single from" && $0.releaseGroup != nil }
                .compactMap { $0.releaseGroup?.title }
        }

        // Extract review URLs (type == "review")
        var reviewURLs: [String] = []
        if let relations = relationsResponse.relations {
            reviewURLs = relations
                .filter { $0.type == "review" && $0.url != nil }
                .compactMap { $0.url?.resource }
        }

        #if DEBUG
        print("🔗 [MusicBrainz] Found \(singles.count) singles: \(singles)")
        print("🔗 [MusicBrainz] Found \(reviewURLs.count) review URLs: \(reviewURLs)")
        #endif

        return ReleaseGroupRelationsResult(singles: singles, reviewURLs: reviewURLs)
    }

    /// Get sorted candidates using existing matching logic (extracted for reuse)
    private func getSortedCandidates(in releases: [MusicBrainzRelease], searchArtist: String, searchAlbum: String) -> [MusicBrainzRelease] {
        // Filter releases that match BOTH artist AND album title
        let matchingReleases = releases.filter { release in
            // Artist check
            guard let artistCredit = release.artistCredit?.first else { return false }
            let releaseArtist = artistCredit.name.lowercased()
            let searchArtistLower = searchArtist.lowercased()
            let artistMatches = releaseArtist.contains(searchArtistLower) || searchArtistLower.contains(releaseArtist)

            // Title check using word overlap (at least 50% common words)
            let searchWords = Set(searchAlbum.lowercased().split(separator: " ").filter { $0.count > 1 }) // Ignore single-char words
            let releaseWords = Set(release.title.lowercased().split(separator: " ").filter { $0.count > 1 })

            // Require at least 50% word overlap to avoid false matches
            let commonWords = searchWords.intersection(releaseWords)
            let maxWords = max(searchWords.count, releaseWords.count)
            let overlapPercentage = maxWords > 0 ? Double(commonWords.count) / Double(maxWords) : 0.0
            let titleMatches = overlapPercentage >= 0.5

            #if DEBUG
            if !titleMatches && artistMatches {
                print("🔍 [MusicBrainz] Filtered out: '\(release.title)' (overlap: \(Int(overlapPercentage * 100))%)")
            }
            #endif

            return artistMatches && titleMatches
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
