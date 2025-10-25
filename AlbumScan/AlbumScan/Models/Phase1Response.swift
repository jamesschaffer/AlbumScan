import Foundation

/// Response structure for Phase 1: Fast Album Identification
/// Returns basic metadata without web search or review generation
struct Phase1Response: Codable {
    let success: Bool
    let artistName: String?
    let albumTitle: String?
    let releaseYear: String?
    let genres: [String]?
    let recordLabel: String?
    let errorMessage: String?

    enum CodingKeys: String, CodingKey {
        case success
        case artistName
        case albumTitle
        case releaseYear
        case genres
        case recordLabel
        case errorMessage
    }

    /// Check if this is a successful identification
    var isSuccess: Bool {
        return success && artistName != nil && albumTitle != nil
    }

    /// Get a displayable error message
    var displayError: String {
        return errorMessage ?? "Could not identify album cover"
    }
}
