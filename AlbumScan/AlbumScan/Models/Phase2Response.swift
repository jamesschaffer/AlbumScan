import Foundation

/// Response structure for Phase 2: Deep Review Generation
/// Returns comprehensive review with web search-powered analysis
struct Phase2Response: Codable {
    let contextSummary: String
    let contextBullets: [String]
    let rating: Double
    let recommendation: String
    let keyTracks: [String]

    enum CodingKeys: String, CodingKey {
        case contextSummary = "context_summary"
        case contextBullets = "context_bullets"
        case rating
        case recommendation
        case keyTracks = "key_tracks"
    }

    /// Validate that this is a complete review
    var isValid: Bool {
        return !contextSummary.isEmpty &&
               !contextBullets.isEmpty &&
               rating >= 0 && rating <= 10 &&
               !recommendation.isEmpty &&
               !keyTracks.isEmpty
    }

    /// Get recommendation emoji
    var recommendationEmoji: String {
        switch recommendation {
        case "ESSENTIAL": return "💎"
        case "RECOMMENDED": return "👍"
        case "SKIP": return "😐"
        case "AVOID": return "💩"
        default: return "❓"
        }
    }
}
