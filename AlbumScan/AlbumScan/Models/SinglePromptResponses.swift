import Foundation

// MARK: - Single-Prompt Album Identification Response Models

/// Observation data extracted from the album cover (Phase 1)
struct AlbumObservation: Codable {
    let extractedText: String
    let albumDescription: String
    let textConfidence: String // "high", "medium", "low"
    let labelLogoVisible: Bool
    let visuallyDistinctive: Bool
    let additionalDetails: String?
}

/// Search request when LLM needs external search (Phase 3)
struct SearchRequest: Codable {
    enum Strategy: String, Codable {
        case metadata
        case visual
    }

    let strategy: Strategy
    let query: String
    let reason: String
    let observation: AlbumObservation
}

/// Successful identification response (Type A & C from spec)
struct SuccessfulIdentification: Codable {
    let success: Bool // Always true
    let artistName: String
    let albumTitle: String
    let releaseYear: String
    let genres: [String]
    let recordLabel: String
    let confidence: String // "high", "medium"
    let rationale: String
    let observation: AlbumObservation
}

/// Search fallback needed (Type B from spec)
struct SearchFallbackNeeded: Codable {
    let success: Bool // Always false
    let needSearch: Bool // Always true
    let searchRequest: SearchRequest
}

/// Unresolved identification (Type D from spec)
struct UnresolvedIdentification: Codable {
    let success: Bool // Always false
    let needSearch: Bool // Always false
    let errorMessage: String
}

/// Unified response wrapper for parsing
enum AlbumIdentificationResponse {
    case success(SuccessfulIdentification)
    case searchNeeded(SearchFallbackNeeded)
    case unresolved(UnresolvedIdentification)

    /// Parse JSON data into the appropriate response type
    static func parse(from data: Data) throws -> AlbumIdentificationResponse {
        let decoder = JSONDecoder()

        // First, peek at the structure to determine type
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let success = json["success"] as? Bool ?? false
            let needSearch = json["needSearch"] as? Bool ?? false

            if success {
                // Type A or C - Successful identification
                let successResponse = try decoder.decode(SuccessfulIdentification.self, from: data)
                return .success(successResponse)
            } else if needSearch {
                // Type B - Search fallback needed
                let searchResponse = try decoder.decode(SearchFallbackNeeded.self, from: data)
                return .searchNeeded(searchResponse)
            } else {
                // Type D - Unresolved
                let unresolvedResponse = try decoder.decode(UnresolvedIdentification.self, from: data)
                return .unresolved(unresolvedResponse)
            }
        }

        throw APIError.invalidResponseFormat
    }
}

/// Convert successful identification to Phase1Response for compatibility with existing code
extension SuccessfulIdentification {
    func toPhase1Response() -> Phase1Response {
        return Phase1Response(
            success: true,
            artistName: artistName,
            albumTitle: albumTitle,
            releaseYear: releaseYear,
            genres: genres,
            recordLabel: recordLabel,
            errorMessage: nil
        )
    }
}
