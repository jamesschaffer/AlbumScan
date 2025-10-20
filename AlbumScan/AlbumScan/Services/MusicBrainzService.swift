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
        request.timeoutInterval = 5.0

        print("🔍 [MusicBrainz] Request URL: \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MusicBrainzError.invalidResponse
        }

        print("🔍 [MusicBrainz] Response status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            throw MusicBrainzError.httpError(httpResponse.statusCode)
        }

        let searchResponse = try JSONDecoder().decode(MusicBrainzSearchResponse.self, from: data)

        print("🔍 [MusicBrainz] Found \(searchResponse.count) results")

        // Find the best match by comparing artist names (case-insensitive)
        let bestMatch = searchResponse.releases.first { release in
            guard let artistCredit = release.artistCredit?.first else { return false }
            let releaseArtist = artistCredit.name.lowercased()
            let searchArtist = artist.lowercased()
            return releaseArtist.contains(searchArtist) || searchArtist.contains(releaseArtist)
        }

        if let mbid = bestMatch?.id {
            print("✅ [MusicBrainz] Found MBID: \(mbid)")
            return mbid
        }

        // Fallback: try fuzzy search if no results
        if searchResponse.releases.isEmpty {
            print("🔍 [MusicBrainz] No exact match, trying fuzzy search...")
            return try await fuzzySearchAlbum(artist: artist, album: album)
        }

        // If we have results but no artist match, return first result
        if let firstResult = searchResponse.releases.first {
            print("⚠️ [MusicBrainz] No exact artist match, using first result: \(firstResult.id)")
            return firstResult.id
        }

        print("❌ [MusicBrainz] No results found")
        return nil
    }

    /// Fuzzy search fallback for albums that don't match exactly
    private func fuzzySearchAlbum(artist: String, album: String) async throws -> String? {
        let query = "artist:\(artist) release:\(album)~"

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
        request.timeoutInterval = 5.0

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return nil
        }

        let searchResponse = try JSONDecoder().decode(MusicBrainzSearchResponse.self, from: data)

        if let firstResult = searchResponse.releases.first {
            print("✅ [MusicBrainz] Fuzzy search found MBID: \(firstResult.id)")
            return firstResult.id
        }

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
