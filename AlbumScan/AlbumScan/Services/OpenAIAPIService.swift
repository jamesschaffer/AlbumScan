import Foundation
import UIKit

class OpenAIAPIService: LLMService {
    static let shared = OpenAIAPIService()

    private let apiKey: String
    private let apiURL = "https://api.openai.com/v1/chat/completions"

    // Prompt storage
    private let identificationPrompt: String
    private let searchFinalizationPrompt: String
    private let reviewPrompt: String

    private init() {
        self.apiKey = Config.openAIAPIKey

        // Load prompts from bundle
        guard let identificationURL = Bundle.main.url(forResource: "single_prompt_identification", withExtension: "txt") else {
            fatalError("❌ Could not find single_prompt_identification.txt in bundle")
        }

        guard let searchURL = Bundle.main.url(forResource: "search_finalization", withExtension: "txt") else {
            fatalError("❌ Could not find search_finalization.txt in bundle")
        }

        guard let reviewURL = Bundle.main.url(forResource: "phase3_review_generation", withExtension: "txt") else {
            fatalError("❌ Could not find phase3_review_generation.txt in bundle")
        }

        guard let identificationContent = try? String(contentsOf: identificationURL) else {
            fatalError("❌ Could not read single_prompt_identification.txt")
        }

        guard let searchContent = try? String(contentsOf: searchURL) else {
            fatalError("❌ Could not read search_finalization.txt")
        }

        guard let reviewContent = try? String(contentsOf: reviewURL) else {
            fatalError("❌ Could not read phase3_review_generation.txt")
        }

        self.identificationPrompt = identificationContent
        self.searchFinalizationPrompt = searchContent
        self.reviewPrompt = reviewContent

        print("✅ [OpenAIAPIService] Loaded identification prompt from bundle")
        print("✅ [OpenAIAPIService] Loaded search finalization prompt from bundle")
        print("✅ [OpenAIAPIService] Loaded review prompt from bundle")
    }

    // MARK: - Single-Prompt Identification (Call 1)

    func executeSinglePromptIdentification(image: UIImage) async throws -> AlbumIdentificationResponse {
        print("🔍 [OpenAI ID Call 1] Starting single-prompt identification...")

        // Convert image to base64
        guard let base64Image = convertImageToBase64(image) else {
            throw APIError.imageProcessingFailed
        }
        print("✅ [OpenAI ID Call 1] Image converted to base64 (\(base64Image.count) bytes)")

        // Build request (using gpt-4o WITHOUT search capability)
        let request = try buildIdentificationRequest(base64Image: base64Image)

        // Make API call
        print("📡 [OpenAI ID Call 1] Sending request...")
        let (data, response) = try await URLSession.shared.data(for: request)
        print("📡 [OpenAI ID Call 1] Received response (\(data.count) bytes)")

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        print("📡 [OpenAI ID Call 1] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let responseBody = String(data: data, encoding: .utf8) {
                print("❌ [OpenAI ID Call 1] Error: \(responseBody)")
            }
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        // Parse response
        let apiResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        // Log token usage
        if let usage = apiResponse.usage {
            let totalTokens = usage.prompt_tokens + usage.completion_tokens
            print("💰 [OpenAI ID Call 1] Tokens: \(usage.prompt_tokens) input + \(usage.completion_tokens) output = \(totalTokens) total")
        }

        return try parseIdentificationResponse(from: apiResponse)
    }

    // MARK: - Search Finalization (Call 2)

    func executeSearchFinalization(image: UIImage, searchRequest: SearchRequest) async throws -> AlbumIdentificationResponse {
        print("🔍 [OpenAI ID Call 2] Starting search finalization...")
        print("🔍 [OpenAI ID Call 2] Search query: \(searchRequest.query)")

        // Convert image to base64
        guard let base64Image = convertImageToBase64(image) else {
            throw APIError.imageProcessingFailed
        }

        // Build prompt with search request data
        let prompt = searchFinalizationPrompt
            .replacingOccurrences(of: "{extractedText}", with: searchRequest.observation.extractedText)
            .replacingOccurrences(of: "{albumDescription}", with: searchRequest.observation.albumDescription)
            .replacingOccurrences(of: "{textConfidence}", with: searchRequest.observation.textConfidence)
            .replacingOccurrences(of: "{searchQuery}", with: searchRequest.query)

        // Build request (using gpt-4o-search-preview WITH search capability)
        let request = try buildSearchFinalizationRequest(base64Image: base64Image, prompt: prompt)

        // Make API call
        print("📡 [OpenAI ID Call 2] Sending request...")
        let (data, response) = try await URLSession.shared.data(for: request)
        print("📡 [OpenAI ID Call 2] Received response (\(data.count) bytes)")

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        print("📡 [OpenAI ID Call 2] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let responseBody = String(data: data, encoding: .utf8) {
                print("❌ [OpenAI ID Call 2] Error: \(responseBody)")
            }
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        // Parse response
        let apiResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        // Log token usage
        if let usage = apiResponse.usage {
            let totalTokens = usage.prompt_tokens + usage.completion_tokens
            print("💰 [OpenAI ID Call 2] Tokens: \(usage.prompt_tokens) input + \(usage.completion_tokens) output = \(totalTokens) total")
        }

        return try parseIdentificationResponse(from: apiResponse)
    }

    // MARK: - Review Generation (unchanged from original)

    func generateReviewPhase2(
        artistName: String,
        albumTitle: String,
        releaseYear: String,
        genres: [String],
        recordLabel: String
    ) async throws -> Phase2Response {
        print("🔑 [OpenAI Review] Starting review generation...")

        // Build prompt with album data
        let genresString = genres.joined(separator: ", ")
        let prompt = reviewPrompt
            .replacingOccurrences(of: "{artistName}", with: artistName)
            .replacingOccurrences(of: "{albumTitle}", with: albumTitle)
            .replacingOccurrences(of: "{releaseYear}", with: releaseYear)
            .replacingOccurrences(of: "{genres}", with: genresString)
            .replacingOccurrences(of: "{recordLabel}", with: recordLabel)

        // Build request with web search enabled
        let request = try buildReviewRequest(prompt: prompt)

        // Make API call
        print("📡 [OpenAI Review] Sending request...")
        let (data, response) = try await URLSession.shared.data(for: request)
        print("📡 [OpenAI Review] Received response (\(data.count) bytes)")

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        print("📡 [OpenAI Review] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let responseBody = String(data: data, encoding: .utf8) {
                print("❌ [OpenAI Review] Error: \(responseBody)")
            }
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        // Parse response
        let apiResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        return try parsePhase2Response(from: apiResponse)
    }

    // MARK: - LLMService Protocol Compliance (for backwards compatibility)

    func executePhase1A(image: UIImage) async throws -> Phase1AResponse {
        // This is called by old code - redirect to new single-prompt flow
        // But we can't fully handle this with the old interface, so throw an error
        fatalError("executePhase1A is deprecated for single-prompt flow. Use executeSinglePromptIdentification instead.")
    }

    func executePhase1B(phase1AData: Phase1AResponse) async throws -> Phase1Response {
        // This is called by old code - not applicable in single-prompt flow
        fatalError("executePhase1B is deprecated for single-prompt flow.")
    }

    // MARK: - Request Builders

    private func buildIdentificationRequest(base64Image: String) throws -> URLRequest {
        guard let url = URL(string: apiURL) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60  // Increased for vision + large image processing

        let body: [String: Any] = [
            "model": "gpt-4o",  // Regular model (NO search capability)
            "max_tokens": 1000,
            "response_format": ["type": "json_object"],  // Enforce JSON output
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": identificationPrompt
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

    private func buildSearchFinalizationRequest(base64Image: String, prompt: String) throws -> URLRequest {
        guard let url = URL(string: apiURL) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60  // Longer timeout for search

        let body: [String: Any] = [
            "model": "gpt-4o-search-preview",  // Search-enabled model
            "max_tokens": 1000,
            // Note: response_format not supported with web_search
            "messages": [
                [
                    "role": "user",
                    "content": prompt  // Text-only - no image needed (observation data already in prompt)
                ]
            ]
            // Note: Web search is automatic with gpt-4o-search-preview
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func buildReviewRequest(prompt: String) throws -> URLRequest {
        guard let url = URL(string: apiURL) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "model": "gpt-4o-search-preview",  // Search-enabled for review context
            "max_tokens": 1500,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    // MARK: - Response Parsers

    private func parseIdentificationResponse(from apiResponse: OpenAIResponse) throws -> AlbumIdentificationResponse {
        guard let choice = apiResponse.choices.first,
              let content = choice.message.content else {
            print("❌ [OpenAI] No content in response")
            throw APIError.invalidResponseFormat
        }

        print("📝 [OpenAI] Raw response:\n\(content)")

        // Clean up response - strip markdown code fences if present
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
            let response = try AlbumIdentificationResponse.parse(from: jsonData)
            print("✅ [OpenAI] Successfully parsed identification response")
            return response
        } catch {
            print("❌ [OpenAI] JSON parsing error: \(error)")
            throw APIError.invalidResponseFormat
        }
    }

    private func parsePhase2Response(from apiResponse: OpenAIResponse) throws -> Phase2Response {
        guard let choice = apiResponse.choices.first,
              let content = choice.message.content else {
            print("❌ [OpenAI Review] No content in response")
            throw APIError.invalidResponseFormat
        }

        print("📝 [OpenAI Review] Raw response:\n\(content)")

        // Clean up response
        var cleanedText = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanedText.hasPrefix("```json") {
            cleanedText = cleanedText.replacingOccurrences(of: "```json", with: "")
            cleanedText = cleanedText.replacingOccurrences(of: "```", with: "")
            cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
            print("📝 [OpenAI Review] Extracted JSON from code fence")
        }

        guard let jsonData = cleanedText.data(using: .utf8) else {
            throw APIError.invalidResponseFormat
        }

        do {
            let phase2Response = try JSONDecoder().decode(Phase2Response.self, from: jsonData)
            print("✅ [OpenAI Review] Successfully parsed")
            return phase2Response
        } catch {
            print("❌ [OpenAI Review] JSON parsing error: \(error)")
            throw APIError.invalidResponseFormat
        }
    }

    // MARK: - Helper Methods

    private func convertImageToBase64(_ image: UIImage) -> String? {
        // Use much lower quality for API transmission
        // OpenAI vision doesn't need high-res to read album text
        // 0.4 quality on 1024x1024 image = ~300-500KB (vs 3MB at 0.8)
        guard let imageData = image.jpegData(compressionQuality: 0.4) else {
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
