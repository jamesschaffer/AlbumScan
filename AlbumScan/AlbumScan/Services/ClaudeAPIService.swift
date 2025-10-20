import Foundation
import UIKit

class ClaudeAPIService {
    static let shared = ClaudeAPIService()

    private let apiKey: String
    private let apiURL = "https://api.anthropic.com/v1/messages"

    private init() {
        // TODO: Load from environment or secure storage
        // For now, this is a placeholder
        self.apiKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"] ?? ""
    }

    func identifyAlbum(image: UIImage) async throws -> AlbumResponse {
        guard !apiKey.isEmpty else {
            throw APIError.missingAPIKey
        }

        // Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw APIError.imageProcessingFailed
        }
        let base64Image = imageData.base64EncodedString()

        // Construct API request
        let request = try buildRequest(base64Image: base64Image)

        // Make API call
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        // Parse response
        let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)

        // Extract album information from response
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
        request.timeoutInterval = 10

        let prompt = """
        You are an expert music historian and critic. Analyze this album cover and provide detailed information about the album.

        Your response must be in valid JSON format with the following structure:
        {
          "album_title": "string",
          "artist_name": "string",
          "release_year": "string",
          "genres": ["string"],
          "record_label": "string",
          "context_summary": "string (2-3 sentences about cultural significance)",
          "context_bullets": ["string (3-5 bullet points with specific evidence)"],
          "rating": number (0-10),
          "recommendation": "ESSENTIAL|RECOMMENDED|SKIP|AVOID",
          "key_tracks": ["string"],
          "album_art_url": "string (optional)"
        }

        Guidelines:
        - Be honest and critical - call out mediocre or bad albums explicitly
        - Focus on musical merit, cultural impact, and artistic significance
        - Provide specific evidence (chart positions, sales, critical scores, influence)
        - NEVER mention price, monetary value, pressing details, or collectibility
        - Evaluate albums purely on musical merit - separate art from artist controversies
        - Use the recommendation categories: ESSENTIAL (💎), RECOMMENDED (👍), SKIP (😐), AVOID (💩)

        Return only the JSON object, no additional text.
        """

        let body: [String: Any] = [
            "model": "claude-3-5-sonnet-20241022",
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
            throw APIError.invalidResponseFormat
        }

        // Parse JSON from text content
        guard let jsonData = textContent.data(using: .utf8) else {
            throw APIError.invalidResponseFormat
        }

        let albumResponse = try JSONDecoder().decode(AlbumResponse.self, from: jsonData)
        return albumResponse
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
