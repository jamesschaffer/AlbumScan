import Foundation
import UIKit

class ClaudeAPIService {
    static let shared = ClaudeAPIService()

    private let apiKey: String
    private let apiURL = "https://api.anthropic.com/v1/messages"
    private let systemPrompt: String
    private let phase2Prompt: String

    // Four-Phase Architecture Prompts
    private let phase1APrompt: String  // Vision extraction (no web search)
    private let phase1BPrompt: String  // Web search mapping
    private let phase3Prompt: String   // Review generation

    private init() {
        // Load API key from Config (which reads from Secrets.plist or environment)
        self.apiKey = Config.claudeAPIKey

        // Legacy system prompt (using fallback for old flow)
        self.systemPrompt = Self.defaultPrompt

        // Load Phase 2 prompt (deep review)
        // Try with subdirectory first, then without (Xcode may flatten the structure)
        if let promptPath = Bundle.main.path(forResource: "album_review", ofType: "txt", inDirectory: "Prompts"),
           let promptContent = try? String(contentsOfFile: promptPath, encoding: .utf8) {
            self.phase2Prompt = promptContent
            print("✅ [ClaudeAPIService] Loaded Phase 2 prompt from Prompts subdirectory")
        } else if let promptPath = Bundle.main.path(forResource: "album_review", ofType: "txt"),
                  let promptContent = try? String(contentsOfFile: promptPath, encoding: .utf8) {
            self.phase2Prompt = promptContent
            print("✅ [ClaudeAPIService] Loaded Phase 2 prompt from root bundle")
        } else {
            self.phase2Prompt = "Review this album."
            print("⚠️ [ClaudeAPIService] Could not find album_review.txt, using fallback")
        }

        // Load Phase 1A prompt (vision extraction)
        if let promptPath = Bundle.main.path(forResource: "phase1a_vision_extraction", ofType: "txt", inDirectory: "Prompts"),
           let promptContent = try? String(contentsOfFile: promptPath, encoding: .utf8) {
            self.phase1APrompt = promptContent
            print("✅ [ClaudeAPIService] Loaded Phase 1A prompt from Prompts subdirectory")
        } else if let promptPath = Bundle.main.path(forResource: "phase1a_vision_extraction", ofType: "txt"),
                  let promptContent = try? String(contentsOfFile: promptPath, encoding: .utf8) {
            self.phase1APrompt = promptContent
            print("✅ [ClaudeAPIService] Loaded Phase 1A prompt from root bundle")
        } else {
            self.phase1APrompt = "Extract text and describe the album cover."
            print("⚠️ [ClaudeAPIService] Could not find phase1a_vision_extraction.txt, using fallback")
        }

        // Load Phase 1B prompt (web search mapping)
        if let promptPath = Bundle.main.path(forResource: "phase1b_web_search_mapping", ofType: "txt", inDirectory: "Prompts"),
           let promptContent = try? String(contentsOfFile: promptPath, encoding: .utf8) {
            self.phase1BPrompt = promptContent
            print("✅ [ClaudeAPIService] Loaded Phase 1B prompt from Prompts subdirectory")
        } else if let promptPath = Bundle.main.path(forResource: "phase1b_web_search_mapping", ofType: "txt"),
                  let promptContent = try? String(contentsOfFile: promptPath, encoding: .utf8) {
            self.phase1BPrompt = promptContent
            print("✅ [ClaudeAPIService] Loaded Phase 1B prompt from root bundle")
        } else {
            self.phase1BPrompt = "Identify the album using web search."
            print("⚠️ [ClaudeAPIService] Could not find phase1b_web_search_mapping.txt, using fallback")
        }

        // Load Phase 3 prompt (review generation)
        if let promptPath = Bundle.main.path(forResource: "phase3_review_generation", ofType: "txt", inDirectory: "Prompts"),
           let promptContent = try? String(contentsOfFile: promptPath, encoding: .utf8) {
            self.phase3Prompt = promptContent
            print("✅ [ClaudeAPIService] Loaded Phase 3 prompt from Prompts subdirectory")
        } else if let promptPath = Bundle.main.path(forResource: "phase3_review_generation", ofType: "txt"),
                  let promptContent = try? String(contentsOfFile: promptPath, encoding: .utf8) {
            self.phase3Prompt = promptContent
            print("✅ [ClaudeAPIService] Loaded Phase 3 prompt from root bundle")
        } else {
            self.phase3Prompt = "Write a review for this album."
            print("⚠️ [ClaudeAPIService] Could not find phase3_review_generation.txt, using fallback")
        }
    }

    func identifyAlbum(image: UIImage) async throws -> AlbumResponse {
        print("🔑 [ClaudeAPI] Starting identifyAlbum...")

        guard !apiKey.isEmpty else {
            print("❌ [ClaudeAPI] API key is missing!")
            throw APIError.missingAPIKey
        }
        print("✅ [ClaudeAPI] API key is present")

        // Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ [ClaudeAPI] Failed to convert image to JPEG")
            throw APIError.imageProcessingFailed
        }
        let base64Image = imageData.base64EncodedString()
        print("✅ [ClaudeAPI] Image converted to base64 (\(imageData.count) bytes)")

        // Construct API request
        print("🔨 [ClaudeAPI] Building request...")
        let request = try buildRequest(base64Image: base64Image)

        // Make API call
        print("📡 [ClaudeAPI] Sending request to Claude API...")
        let (data, response) = try await URLSession.shared.data(for: request)
        print("📡 [ClaudeAPI] Received response (\(data.count) bytes)")

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ [ClaudeAPI] Invalid HTTP response")
            throw APIError.invalidResponse
        }

        print("📡 [ClaudeAPI] HTTP Status Code: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let responseBody = String(data: data, encoding: .utf8) {
                print("❌ [ClaudeAPI] Error response body: \(responseBody)")
            }
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        // Parse response
        print("🔍 [ClaudeAPI] Parsing Claude API response...")
        let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)

        // Extract album information from response
        print("🔍 [ClaudeAPI] Extracting album information...")
        return try parseAlbumResponse(from: apiResponse)
    }

    // MARK: - Shared Phase 1 Response Parser

    private func parsePhase1Response(from apiResponse: ClaudeAPIResponse) throws -> Phase1Response {
        guard let textContent = apiResponse.content.first(where: { $0.type == "text" })?.text else {
            print("❌ [ClaudeAPI Phase1] No text content found")
            throw APIError.invalidResponseFormat
        }

        print("📝 [ClaudeAPI Phase1] Raw response:\n\(textContent)")

        // Extract JSON from <json_response> tags if present
        var cleanedText = textContent.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for <json_response> tags
        if let startRange = cleanedText.range(of: "<json_response>"),
           let endRange = cleanedText.range(of: "</json_response>") {
            let jsonStart = startRange.upperBound
            let jsonEnd = endRange.lowerBound
            cleanedText = String(cleanedText[jsonStart..<jsonEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Also strip markdown code fences if present
        if cleanedText.hasPrefix("```json") {
            cleanedText = cleanedText.replacingOccurrences(of: "```json", with: "")
            cleanedText = cleanedText.replacingOccurrences(of: "```", with: "")
            cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let jsonData = cleanedText.data(using: .utf8) else {
            throw APIError.invalidResponseFormat
        }

        do {
            let phase1Response = try JSONDecoder().decode(Phase1Response.self, from: jsonData)
            print("✅ [ClaudeAPI Phase1] Successfully parsed")
            return phase1Response
        } catch {
            print("❌ [ClaudeAPI Phase1] JSON parsing error: \(error)")
            throw APIError.invalidResponseFormat
        }
    }

    // MARK: - Phase 2: Deep Review Generation

    func generateReviewPhase2(artistName: String, albumTitle: String, releaseYear: String, genres: [String], recordLabel: String) async throws -> Phase2Response {
        print("🔑 [ClaudeAPI Phase2] Starting review generation...")

        guard !apiKey.isEmpty else {
            print("❌ [ClaudeAPI Phase2] API key is missing!")
            throw APIError.missingAPIKey
        }

        // Build metadata string for Phase 2
        let genresString = genres.joined(separator: ", ")
        let metadataPrompt = phase2Prompt
            .replacingOccurrences(of: "{artist_name}", with: artistName)
            .replacingOccurrences(of: "{album_title}", with: albumTitle)
            .replacingOccurrences(of: "{release_year}", with: releaseYear)
            .replacingOccurrences(of: "{genres}", with: genresString)
            .replacingOccurrences(of: "{record_label}", with: recordLabel)

        // Build Phase 2 request (with web search)
        let request = try buildPhase2Request(prompt: metadataPrompt)

        // Make API call
        print("📡 [ClaudeAPI Phase2] Sending request...")
        let (data, response) = try await URLSession.shared.data(for: request)
        print("📡 [ClaudeAPI Phase2] Received response (\(data.count) bytes)")

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        print("📡 [ClaudeAPI Phase2] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let responseBody = String(data: data, encoding: .utf8) {
                print("❌ [ClaudeAPI Phase2] Error: \(responseBody)")
            }
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        // Parse response
        let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
        return try parsePhase2Response(from: apiResponse)
    }

    private func buildPhase2Request(prompt: String) throws -> URLRequest {
        guard let url = URL(string: apiURL) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 15  // Longer timeout for Phase 2 review

        let body: [String: Any] = [
            "model": "claude-sonnet-4-5-20250929",  // Use Sonnet for Phase 2
            "max_tokens": 1500,  // Larger response for review
            "temperature": 0.3,  // Slightly creative
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ]
                    ]
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func parsePhase2Response(from apiResponse: ClaudeAPIResponse) throws -> Phase2Response {
        guard let textContent = apiResponse.content.first(where: { $0.type == "text" })?.text else {
            print("❌ [ClaudeAPI Phase2] No text content found")
            throw APIError.invalidResponseFormat
        }

        print("📝 [ClaudeAPI Phase2] Raw response:\n\(textContent)")

        // Extract JSON from markdown code fence or from the response
        var cleanedText = textContent.trimmingCharacters(in: .whitespacesAndNewlines)

        // Try to find JSON within code fence (```json ... ```)
        if let jsonStart = cleanedText.range(of: "```json"),
           let jsonEnd = cleanedText.range(of: "```", range: jsonStart.upperBound..<cleanedText.endIndex) {
            // Extract content between code fences
            let startIndex = jsonStart.upperBound
            let endIndex = jsonEnd.lowerBound
            cleanedText = String(cleanedText[startIndex..<endIndex])
            cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
            print("📝 [ClaudeAPI Phase2] Extracted JSON from code fence")
        } else if cleanedText.hasPrefix("```json") {
            // Fallback: strip code fences if at start
            cleanedText = cleanedText.replacingOccurrences(of: "```json", with: "")
            cleanedText = cleanedText.replacingOccurrences(of: "```", with: "")
            cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let jsonData = cleanedText.data(using: .utf8) else {
            throw APIError.invalidResponseFormat
        }

        do {
            let phase2Response = try JSONDecoder().decode(Phase2Response.self, from: jsonData)
            print("✅ [ClaudeAPI Phase2] Successfully parsed")
            return phase2Response
        } catch {
            print("❌ [ClaudeAPI Phase2] JSON parsing error: \(error)")
            throw APIError.invalidResponseFormat
        }
    }

    private func buildRequest(base64Image: String) throws -> URLRequest {
        guard let url = URL(string: apiURL) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 30

        // Use the loaded prompt from file
        let prompt = systemPrompt

        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 1500,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ],
                        [
                            "type": "text",
                            "text": prompt
                        ]
                    ]
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func parseAlbumResponse(from apiResponse: ClaudeAPIResponse) throws -> AlbumResponse {
        // Extract text content from Claude's response
        guard let textContent = apiResponse.content.first(where: { $0.type == "text" })?.text else {
            print("❌ [ClaudeAPI] No text content found in response")
            throw APIError.invalidResponseFormat
        }

        print("📝 [ClaudeAPI] Raw text from Claude:\n\(textContent)")

        // Strip markdown code fences if present
        var cleanedText = textContent.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanedText.hasPrefix("```json") {
            cleanedText = cleanedText.replacingOccurrences(of: "```json", with: "")
            cleanedText = cleanedText.replacingOccurrences(of: "```", with: "")
            cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
            print("✂️ [ClaudeAPI] Stripped markdown code fences")
        }

        // Parse JSON from text content
        guard let jsonData = cleanedText.data(using: .utf8) else {
            print("❌ [ClaudeAPI] Failed to convert text to data")
            throw APIError.invalidResponseFormat
        }

        do {
            let albumResponse = try JSONDecoder().decode(AlbumResponse.self, from: jsonData)
            print("✅ [ClaudeAPI] Successfully parsed album response")
            return albumResponse
        } catch {
            print("❌ [ClaudeAPI] JSON parsing error: \(error)")
            print("❌ [ClaudeAPI] Failed to parse JSON:\n\(cleanedText)")
            throw APIError.invalidResponseFormat
        }
    }
}

// MARK: - Supporting Types

struct ClaudeAPIResponse: Codable {
    let content: [ContentBlock]
    let model: String
    let role: String

    struct ContentBlock: Codable {
        let type: String
        let text: String?
    }
}

enum APIError: LocalizedError {
    case missingAPIKey
    case imageProcessingFailed
    case invalidURL
    case invalidResponse
    case invalidResponseFormat
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key not configured"
        case .imageProcessingFailed:
            return "Failed to process image"
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidResponseFormat:
            return "Could not parse album information"
        case .httpError(let code):
            return "Server error: \(code)"
        }
    }
}

// MARK: - Default Prompt Fallback

extension ClaudeAPIService {
    static let defaultPrompt = """
You are an experienced music critic analyzing this album cover. Identify the album and write a concise, honest review.

Your response must be in valid JSON format with the following structure:
{
  "album_title": "string",
  "artist_name": "string",
  "release_year": "string",
  "genres": ["string"],
  "record_label": "string",
  "context_summary": "string (2-3 opening sentences in plain, direct language. Capture the album's core essence and importance. Answer: Why does this album matter? What makes it essential or not? Be honest about quality and legacy. If mediocre or bad, say so clearly.)",
  "context_bullets": ["string (3-5 ONE-sentence bullet points with specific evidence: impact examples, critical reception with ratings/scores if notable, specific songs or innovations, reputation evolution, commercial success/failure, influence on other artists/genres)"],
  "rating": number (0-10),
  "recommendation": "ESSENTIAL|RECOMMENDED|SKIP|AVOID",
  "key_tracks": ["string"],
  "album_art_url": "string (optional)"
}

Critical Guidelines:
- Be honest and direct—no hedging or unnecessary qualifiers
- Focus on what actually matters about this album
- Avoid generic praise or criticism—be specific
- If the album has no particular significance, state that plainly
- Keep bullet points to ONE sentence maximum
- Provide specific evidence (chart positions, sales, critical scores, influence)
- NEVER mention price, monetary value, pressing details, or collectibility
- Tone: Concise, decisive, evidence-based, not flowery

Recommendation Categories (use emojis in your reasoning):
- ESSENTIAL (💎) - Must own for any serious music collection
- RECOMMENDED (👍) - Worth buying if you're a fan of the artist/genre/era
- SKIP (😐) - Not worth your time or money
- AVOID (💩) - Actively bad; belongs in the trash

Return only the JSON object, no additional text.
"""

    // MARK: - Four-Phase API Methods

    /// Phase 1A: Vision Extraction (NO web search)
    /// Extracts observable text and visual description from album cover
    /// Uses: Haiku 4.5, NO web search, fast (1-2s)
    func executePhase1A(image: UIImage) async throws -> Phase1AResponse {
        print("🔍 [ClaudeAPI Phase1A] Starting vision extraction...")

        // Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw APIError.imageProcessingFailed
        }
        let base64Image = imageData.base64EncodedString()
        print("✅ [ClaudeAPI Phase1A] Image converted to base64 (\(imageData.count) bytes)")

        // Build request
        let request = try buildPhase1ARequest(base64Image: base64Image)

        // Make API call
        print("📡 [ClaudeAPI Phase1A] Sending request...")
        let (data, response) = try await URLSession.shared.data(for: request)
        print("📡 [ClaudeAPI Phase1A] Received response (\(data.count) bytes)")

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        print("📡 [ClaudeAPI Phase1A] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let responseBody = String(data: data, encoding: .utf8) {
                print("❌ [ClaudeAPI Phase1A] Error: \(responseBody)")
            }
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        // Parse response
        let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
        return try parsePhase1AResponse(from: apiResponse)
    }

    /// Phase 1B: Web Search Mapping (WITH web search)
    /// Uses extracted data to identify album via web search
    /// Uses: Haiku 4.5, web search enabled, 1-2s
    func executePhase1B(phase1AData: Phase1AResponse) async throws -> Phase1Response {
        print("🔍 [ClaudeAPI Phase1B] Starting web search mapping...")

        // Build prompt with extracted data
        let prompt = phase1BPrompt
            .replacingOccurrences(of: "{extractedText}", with: phase1AData.extractedText)
            .replacingOccurrences(of: "{albumDescription}", with: phase1AData.albumDescription)

        // Build request with web search enabled
        let request = try buildPhase1BRequest(prompt: prompt)

        // Make API call
        print("📡 [ClaudeAPI Phase1B] Sending request...")
        let (data, response) = try await URLSession.shared.data(for: request)
        print("📡 [ClaudeAPI Phase1B] Received response (\(data.count) bytes)")

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        print("📡 [ClaudeAPI Phase1B] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let responseBody = String(data: data, encoding: .utf8) {
                print("❌ [ClaudeAPI Phase1B] Error: \(responseBody)")
            }
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        // Parse response (same format as existing Phase1Response)
        let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
        return try parsePhase1Response(from: apiResponse)
    }

    // MARK: - Request Builders

    private func buildPhase1ARequest(base64Image: String) throws -> URLRequest {
        guard let url = URL(string: apiURL) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 10  // Fast timeout for Phase 1A

        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",  // Haiku 4.5 for speed
            "max_tokens": 200,  // Small response
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ],
                        [
                            "type": "text",
                            "text": phase1APrompt
                        ]
                    ]
                ]
            ]
            // NO web search - pure vision extraction
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func buildPhase1BRequest(prompt: String) throws -> URLRequest {
        guard let url = URL(string: apiURL) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 15  // Longer for web search

        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",  // Haiku 4.5 for speed + cost
            "max_tokens": 300,  // Small response
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            // Enable web search for album identification
            "tools": [[
                "type": "web_search_20250305",
                "name": "web_search",
                "max_uses": 5
            ]]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    // MARK: - Response Parsers

    private func parsePhase1AResponse(from apiResponse: ClaudeAPIResponse) throws -> Phase1AResponse {
        guard let textContent = apiResponse.content.first(where: { $0.type == "text" })?.text else {
            print("❌ [ClaudeAPI Phase1A] No text content in response")
            throw APIError.invalidResponseFormat
        }

        print("📝 [ClaudeAPI Phase1A] Raw response:\n\(textContent)")

        // Parse JSON from response
        guard let jsonData = textContent.data(using: .utf8) else {
            throw APIError.invalidResponseFormat
        }

        let phase1AResponse = try JSONDecoder().decode(Phase1AResponse.self, from: jsonData)
        print("✅ [ClaudeAPI Phase1A] Successfully parsed")
        return phase1AResponse
    }
}
