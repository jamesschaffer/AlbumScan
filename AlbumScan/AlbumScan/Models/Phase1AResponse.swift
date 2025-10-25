import Foundation

/// Response from Phase 1A: Vision Extraction
/// Extracts observable text and visual description from album cover
/// NO identification - pure vision extraction
struct Phase1AResponse: Codable {
    let extractedText: String       // All visible text on cover
    let albumDescription: String    // Visual description (colors, imagery, style)
}
