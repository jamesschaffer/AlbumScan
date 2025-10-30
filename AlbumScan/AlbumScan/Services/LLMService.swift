import UIKit

/// Protocol defining the interface for LLM service providers
/// Supports both Claude and OpenAI implementations
protocol LLMService {
    /// Phase 1A: Vision Extraction (NO web search)
    /// Analyzes the album cover image and extracts text and visual description
    /// - Parameter image: The album cover image to analyze
    /// - Returns: Phase1AResponse containing extracted text, description, and confidence
    func executePhase1A(image: UIImage) async throws -> Phase1AResponse

    /// Phase 1B: Web Search Mapping (WITH web search)
    /// Uses extracted data from Phase 1A to identify the album via web search
    /// - Parameter phase1AData: The data extracted from Phase 1A
    /// - Returns: Phase1Response containing album metadata (artist, title, year, etc.)
    func executePhase1B(phase1AData: Phase1AResponse) async throws -> Phase1Response

    /// Phase 2: Review Generation (WITH or WITHOUT web search depending on Ultra)
    /// Generates a detailed review and analysis of the identified album
    /// - Parameters:
    ///   - artistName: The artist name
    ///   - albumTitle: The album title
    ///   - releaseYear: The release year
    ///   - genres: Array of genre strings
    ///   - recordLabel: The record label
    ///   - searchEnabled: Whether Ultra search is enabled (uses gpt-4o-search-preview if true)
    /// - Returns: Phase2Response containing review, rating, and recommendations
    func generateReviewPhase2(
        artistName: String,
        albumTitle: String,
        releaseYear: String,
        genres: [String],
        recordLabel: String,
        searchEnabled: Bool
    ) async throws -> Phase2Response
}
