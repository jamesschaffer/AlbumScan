import Foundation

// MARK: - MusicBrainz Response Models

struct MusicBrainzSearchResponse: Codable {
    let releases: [MusicBrainzRelease]
    let count: Int
}

struct MusicBrainzRelease: Codable {
    let id: String // This is the MBID we need
    let title: String
    let artistCredit: [ArtistCredit]?
    let date: String?
    let country: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case artistCredit = "artist-credit"
        case date
        case country
    }
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
            URLQueryItem(name: "limit", value: "5")
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

                // Find the best match
                return findBestMatch(in: searchResponse.releases, searchArtist: artist, searchAlbum: album)

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

    /// Find the best matching release from search results
    private func findBestMatch(in releases: [MusicBrainzRelease], searchArtist: String, searchAlbum: String) -> String? {
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

        if let bestMatch = sortedReleases.first {
            print("✅ [MusicBrainz] Found MBID: \(bestMatch.id) (country: \(bestMatch.country ?? "unknown"), date: \(bestMatch.date ?? "unknown"))")
            return bestMatch.id
        }

        // If no matching releases, try first result as fallback
        if let firstResult = releases.first {
            print("⚠️ [MusicBrainz] No exact artist match, using first result: \(firstResult.id)")
            return firstResult.id
        }

        print("❌ [MusicBrainz] No matching results")
        return nil
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
