import Foundation

/// Response from Phase 1A: Vision Extraction
/// Extracts observable text and visual description from album cover
/// NO identification - pure vision extraction
struct Phase1AResponse: Codable {
    let extractedText: String       // All visible text on cover
    let albumDescription: String    // Visual description (colors, imagery, style)

    // Optional metadata fields (may be returned by enhanced prompts)
    let textConfidence: String?         // Confidence level of text extraction
    let labelLogoVisible: Bool?         // Whether record label logo is visible
    let visuallyDistinctive: Bool?      // Whether cover is visually distinctive
    let additionalDetails: String?      // Any additional relevant details
}
