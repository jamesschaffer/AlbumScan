import Foundation
import UIKit

class OpenAIAPIService: LLMService {
    static let shared = OpenAIAPIService()

    private let apiKey: String
    private let apiURL = "https://api.openai.com/v1/chat/completions"

    // Prompt storage
    private let phase1APrompt: String
    private let phase1BPrompt: String
    private let phase2Prompt: String

    private init() {
        self.apiKey = Config.openAIAPIKey

        // Load prompts from bundle (same prompts as Claude)
        guard let phase1AURL = Bundle.main.url(forResource: "phase1a_vision_extraction", withExtension: "txt", subdirectory: "Prompts"),
              let phase1BURL = Bundle.main.url(forResource: "phase1b_web_search_mapping", withExtension: "txt", subdirectory: "Prompts"),
              let phase2URL = Bundle.main.url(forResource: "phase2_review_generation", withExtension: "txt", subdirectory: "Prompts"),
              let phase1AContent = try? String(contentsOf: phase1AURL),
              let phase1BContent = try? String(contentsOf: phase1BURL),
              let phase2Content = try? String(contentsOf: phase2URL) else {
            fatalError("Could not load OpenAI prompts from bundle")
        }

        self.phase1APrompt = phase1AContent
        self.phase1BPrompt = phase1BContent
        self.phase2Prompt = phase2Content

        print("✅ [OpenAIAPIService] Loaded Phase 1A prompt from root bundle")
        print("✅ [OpenAIAPIService] Loaded Phase 1B prompt from root bundle")
        print("✅ [OpenAIAPIService] Loaded Phase 2 prompt from root bundle")
    }

    // MARK: - Phase 1A: Vision Extraction (NO web search)

    func executePhase1A(image: UIImage) async throws -> Phase1AResponse {
        print("🔍 [OpenAI Phase1A] Starting vision extraction...")

        // Convert image to base64
        guard let base64Image = convertImageToBase64(image) else {
            throw APIError.imageProcessingFailed
        }
        print("✅ [OpenAI Phase1A] Image converted to base64 (\(base64Image.count) bytes)")

        // Build request
        let request = try buildPhase1ARequest(base64Image: base64Image)

        // Make API call
        print("📡 [OpenAI Phase1A] Sending request...")
        let (data, response) = try await URLSession.shared.data(for: request)
        print("📡 [OpenAI Phase1A] Received response (\(data.count) bytes)")

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        print("📡 [OpenAI Phase1A] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let responseBody = String(data: data, encoding: .utf8) {
                print("❌ [OpenAI Phase1A] Error: \(responseBody)")
            }
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        // Parse response
        let apiResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        // Log token usage
        if let usage = apiResponse.usage {
            let totalTokens = usage.prompt_tokens + usage.completion_tokens
            print("💰 [OpenAI Phase1A] Tokens: \(usage.prompt_tokens) input + \(usage.completion_tokens) output = \(totalTokens) total")
        }

        return try parsePhase1AResponse(from: apiResponse)
    }

    // MARK: - Phase 1B: Web Search Mapping (WITH web search)

    func executePhase1B(phase1AData: Phase1AResponse) async throws -> Phase1Response {
        print("🔍 [OpenAI Phase1B] Starting web search mapping...")

        // Build prompt with extracted data
        let prompt = phase1BPrompt
            .replacingOccurrences(of: "{extractedText}", with: phase1AData.extractedText)
            .replacingOccurrences(of: "{albumDescription}", with: phase1AData.albumDescription)
            .replacingOccurrences(of: "{textConfidence}", with: phase1AData.textConfidence ?? "medium")

        // Build request with web search enabled
        let request = try buildPhase1BRequest(prompt: prompt)

        // Make API call
        print("📡 [OpenAI Phase1B] Sending request...")
        let (data, response) = try await URLSession.shared.data(for: request)
        print("📡 [OpenAI Phase1B] Received response (\(data.count) bytes)")

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        print("📡 [OpenAI Phase1B] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let responseBody = String(data: data, encoding: .utf8) {
                print("❌ [OpenAI Phase1B] Error: \(responseBody)")
            }
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        // Parse response
        let apiResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        // Log token usage
        if let usage = apiResponse.usage {
            let totalTokens = usage.prompt_tokens + usage.completion_tokens
            print("💰 [OpenAI Phase1B] Tokens: \(usage.prompt_tokens) input + \(usage.completion_tokens) output = \(totalTokens) total")
        }

        return try parsePhase1Response(from: apiResponse)
    }

    // MARK: - Phase 2: Review Generation (WITH web search)

    func generateReviewPhase2(
        artistName: String,
        albumTitle: String,
        releaseYear: String,
        genres: [String],
        recordLabel: String
    ) async throws -> Phase2Response {
        print("🔑 [OpenAI Phase2] Starting review generation...")

        // Build prompt with album data
        let genresString = genres.joined(separator: ", ")
        let prompt = phase2Prompt
            .replacingOccurrences(of: "{artistName}", with: artistName)
            .replacingOccurrences(of: "{albumTitle}", with: albumTitle)
            .replacingOccurrences(of: "{releaseYear}", with: releaseYear)
            .replacingOccurrences(of: "{genres}", with: genresString)
            .replacingOccurrences(of: "{recordLabel}", with: recordLabel)

        // Build request with web search enabled
        let request = try buildPhase2Request(prompt: prompt)

        // Make API call
        print("📡 [OpenAI Phase2] Sending request...")
        let (data, response) = try await URLSession.shared.data(for: request)
        print("📡 [OpenAI Phase2] Received response (\(data.count) bytes)")

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        print("📡 [OpenAI Phase2] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let responseBody = String(data: data, encoding: .utf8) {
                print("❌ [OpenAI Phase2] Error: \(responseBody)")
            }
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        // Parse response
        let apiResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        return try parsePhase2Response(from: apiResponse)
    }

    // MARK: - Request Builders

    private func buildPhase1ARequest(base64Image: String) throws -> URLRequest {
        guard let url = URL(string: apiURL) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "model": "gpt-4o",  // Vision-capable model
            "max_tokens": 500,  // Sufficient for Phase 1A JSON response
            "temperature": 0.1,  // Low for consistency
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": phase1APrompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ]
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
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "model": "gpt-4o",
            "max_tokens": 500,
            "temperature": 0.0,
            "messages": [
                [
                    "role": "system",
                    "content": "You are a JSON-only API. Return only valid JSON, never any explanatory text."
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            // Enable web search (OpenAI's equivalent of Claude's web search)
            "tools": [[
                "type": "web_search",
                "web_search": [
                    "search_context_size": "medium"  // low, medium, or high
                ]
            ]]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func buildPhase2Request(prompt: String) throws -> URLRequest {
        guard let url = URL(string: apiURL) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "model": "gpt-4o",
            "max_tokens": 1500,
            "temperature": 0.3,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            // Enable web search for Phase 2
            "tools": [[
                "type": "web_search",
                "web_search": [
                    "search_context_size": "medium"
                ]
            ]]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    // MARK: - Response Parsers

    private func parsePhase1AResponse(from apiResponse: OpenAIResponse) throws -> Phase1AResponse {
        guard let choice = apiResponse.choices.first,
              let content = choice.message.content else {
            print("❌ [OpenAI Phase1A] No content in response")
            throw APIError.invalidResponseFormat
        }

        print("📝 [OpenAI Phase1A] Raw response:\n\(content)")

        // Clean up response - strip markdown code fences
        var cleanedText = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanedText.hasPrefix("```json") {
            cleanedText = cleanedText.replacingOccurrences(of: "```json", with: "")
            cleanedText = cleanedText.replacingOccurrences(of: "```", with: "")
            cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let jsonData = cleanedText.data(using: .utf8) else {
            throw APIError.invalidResponseFormat
        }

        do {
            let phase1AResponse = try JSONDecoder().decode(Phase1AResponse.self, from: jsonData)
            print("✅ [OpenAI Phase1A] Successfully parsed")
            return phase1AResponse
        } catch {
            print("❌ [OpenAI Phase1A] JSON parsing error: \(error)")
            throw APIError.invalidResponseFormat
        }
    }

    private func parsePhase1Response(from apiResponse: OpenAIResponse) throws -> Phase1Response {
        guard let choice = apiResponse.choices.first,
              let content = choice.message.content else {
            print("❌ [OpenAI Phase1B] No content in response")
            throw APIError.invalidResponseFormat
        }

        print("📝 [OpenAI Phase1B] Raw response:\n\(content)")

        // Clean up response
        var cleanedText = content.trimmingCharacters(in: .whitespacesAndNewlines)

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
            print("✅ [OpenAI Phase1B] Successfully parsed")
            return phase1Response
        } catch {
            print("❌ [OpenAI Phase1B] JSON parsing error: \(error)")
            print("❌ [OpenAI Phase1B] Failed to parse: \(cleanedText.prefix(200))...")
            throw APIError.invalidResponseFormat
        }
    }

    private func parsePhase2Response(from apiResponse: OpenAIResponse) throws -> Phase2Response {
        guard let choice = apiResponse.choices.first,
              let content = choice.message.content else {
            print("❌ [OpenAI Phase2] No content in response")
            throw APIError.invalidResponseFormat
        }

        print("📝 [OpenAI Phase2] Raw response:\n\(content)")

        // Clean up response
        var cleanedText = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanedText.hasPrefix("```json") {
            cleanedText = cleanedText.replacingOccurrences(of: "```json", with: "")
            cleanedText = cleanedText.replacingOccurrences(of: "```", with: "")
            cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
            print("📝 [OpenAI Phase2] Extracted JSON from code fence")
        }

        guard let jsonData = cleanedText.data(using: .utf8) else {
            throw APIError.invalidResponseFormat
        }

        do {
            let phase2Response = try JSONDecoder().decode(Phase2Response.self, from: jsonData)
            print("✅ [OpenAI Phase2] Successfully parsed")
            return phase2Response
        } catch {
            print("❌ [OpenAI Phase2] JSON parsing error: \(error)")
            throw APIError.invalidResponseFormat
        }
    }

    // MARK: - Helper Methods

    private func convertImageToBase64(_ image: UIImage) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        return imageData.base64EncodedString()
    }
}

// MARK: - OpenAI API Response Models

struct OpenAIResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [OpenAIChoice]
    let usage: OpenAIUsage?
}

struct OpenAIChoice: Codable {
    let index: Int
    let message: OpenAIMessage
    let finish_reason: String?
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String?
}

struct OpenAIUsage: Codable {
    let prompt_tokens: Int
    let completion_tokens: Int
    let total_tokens: Int
}
