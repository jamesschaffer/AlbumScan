import Foundation
import UIKit

class ClaudeAPIService {
    static let shared = ClaudeAPIService()

    private let apiKey: String
    private let apiURL = "https://api.anthropic.com/v1/messages"
    private let systemPrompt: String

    private init() {
        // Load API key from environment
        self.apiKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"] ?? ""

        // Load prompt from file
        if let promptPath = Bundle.main.path(forResource: "album_identification_v1", ofType: "txt", inDirectory: "Prompts"),
           let promptContent = try? String(contentsOfFile: promptPath, encoding: .utf8) {
            self.systemPrompt = promptContent
        } else {
            // Fallback to embedded prompt if file not found
            self.systemPrompt = Self.defaultPrompt
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
            "model": "claude-sonnet-4-5-20250929",
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
}
