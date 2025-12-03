import Foundation
import UIKit
import FirebaseFunctions

/// Service that proxies OpenAI API calls through Firebase Cloud Functions
/// This provides server-side API key protection and rate limiting
class CloudFunctionsService: LLMService {
    static let shared = CloudFunctionsService()

    private let functions: Functions

    // Prompt storage (loaded from bundle)
    private let identificationPrompt: String
    private let searchFinalizationPrompt: String
    private let reviewPrompt: String
    private let reviewUltraPrompt: String

    private init() {
        // Initialize Firebase Functions
        self.functions = Functions.functions()

        // Use emulator in debug builds if enabled
        #if DEBUG
        // Uncomment the line below to use local emulator during development
        // functions.useEmulator(withHost: "localhost", port: 5001)
        #endif

        // Load prompts from bundle (same as OpenAIAPIService)
        guard let identificationURL = Bundle.main.url(forResource: "single_prompt_identification", withExtension: "txt") else {
            fatalError("❌ Could not find single_prompt_identification.txt in bundle")
        }

        guard let searchURL = Bundle.main.url(forResource: "search_finalization", withExtension: "txt") else {
            fatalError("❌ Could not find search_finalization.txt in bundle")
        }

        guard let reviewURL = Bundle.main.url(forResource: "album_review", withExtension: "txt") else {
            fatalError("❌ Could not find album_review.txt in bundle")
        }

        guard let reviewUltraURL = Bundle.main.url(forResource: "album_review_ultra", withExtension: "txt") else {
            fatalError("❌ Could not find album_review_ultra.txt in bundle")
        }

        guard let identificationContent = try? String(contentsOf: identificationURL) else {
            fatalError("❌ Could not read single_prompt_identification.txt")
        }

        guard let searchContent = try? String(contentsOf: searchURL) else {
            fatalError("❌ Could not read search_finalization.txt")
        }

        guard let reviewContent = try? String(contentsOf: reviewURL) else {
            fatalError("❌ Could not read album_review.txt")
        }

        guard let reviewUltraContent = try? String(contentsOf: reviewUltraURL) else {
            fatalError("❌ Could not read album_review_ultra.txt")
        }

        self.identificationPrompt = identificationContent
        self.searchFinalizationPrompt = searchContent
        self.reviewPrompt = reviewContent
        self.reviewUltraPrompt = reviewUltraContent

        #if DEBUG
        print("✅ [CloudFunctionsService] Initialized with Firebase Functions")
        #endif
    }

    // MARK: - Single-Prompt Identification (Call 1)

    func executeSinglePromptIdentification(image: UIImage) async throws -> AlbumIdentificationResponse {
        #if DEBUG
        print("🔍 [CloudFunctions ID Call 1] Starting single-prompt identification...")
        #endif

        // Convert image to base64
        guard let base64Image = convertImageToBase64(image) else {
            throw APIError.imageProcessingFailed
        }

        #if DEBUG
        print("✅ [CloudFunctions ID Call 1] Image converted to base64 (\(base64Image.count) bytes)")
        #endif

        // Prepare data for Cloud Function
        let data: [String: Any] = [
            "base64Image": base64Image,
            "prompt": identificationPrompt
        ]

        // Call Cloud Function
        #if DEBUG
        print("📡 [CloudFunctions ID Call 1] Calling identifyAlbum function...")
        #endif

        do {
            let result = try await functions.httpsCallable("identifyAlbum").call(data)

            guard let resultData = result.data as? [String: Any],
                  let success = resultData["success"] as? Bool,
                  success,
                  let openAIData = resultData["data"] as? [String: Any] else {
                throw APIError.invalidResponse
            }

            #if DEBUG
            print("📡 [CloudFunctions ID Call 1] Received response")
            #endif

            // Parse the OpenAI response
            return try parseIdentificationResponse(from: openAIData)

        } catch let error as NSError {
            #if DEBUG
            print("❌ [CloudFunctions ID Call 1] Error: \(error.localizedDescription)")
            #endif

            // Handle Firebase Functions specific errors
            if error.domain == FunctionsErrorDomain {
                let code = FunctionsErrorCode(rawValue: error.code)
                switch code {
                case .resourceExhausted:
                    throw APIError.rateLimitExceeded
                case .unauthenticated:
                    throw APIError.appCheckFailed
                case .invalidArgument:
                    throw APIError.invalidRequest
                default:
                    throw APIError.httpError(statusCode: error.code)
                }
            }
            throw error
        }
    }

    // MARK: - Search Finalization (Call 2)

    func executeSearchFinalization(image: UIImage, searchRequest: SearchRequest) async throws -> AlbumIdentificationResponse {
        #if DEBUG
        print("🔍 [CloudFunctions ID Call 2] Starting search finalization...")
        print("🔍 [CloudFunctions ID Call 2] Search query: \(searchRequest.query)")
        #endif

        // Build prompt with search request data
        let prompt = searchFinalizationPrompt
            .replacingOccurrences(of: "{extractedText}", with: searchRequest.observation.extractedText)
            .replacingOccurrences(of: "{albumDescription}", with: searchRequest.observation.albumDescription)
            .replacingOccurrences(of: "{textConfidence}", with: searchRequest.observation.textConfidence)
            .replacingOccurrences(of: "{searchQuery}", with: searchRequest.query)

        // Prepare data for Cloud Function
        let data: [String: Any] = [
            "prompt": prompt
        ]

        // Call Cloud Function
        #if DEBUG
        print("📡 [CloudFunctions ID Call 2] Calling searchFinalizeAlbum function...")
        #endif

        do {
            let result = try await functions.httpsCallable("searchFinalizeAlbum").call(data)

            guard let resultData = result.data as? [String: Any],
                  let success = resultData["success"] as? Bool,
                  success,
                  let openAIData = resultData["data"] as? [String: Any] else {
                throw APIError.invalidResponse
            }

            #if DEBUG
            print("📡 [CloudFunctions ID Call 2] Received response")
            #endif

            return try parseIdentificationResponse(from: openAIData)

        } catch let error as NSError {
            #if DEBUG
            print("❌ [CloudFunctions ID Call 2] Error: \(error.localizedDescription)")
            #endif

            if error.domain == FunctionsErrorDomain {
                let code = FunctionsErrorCode(rawValue: error.code)
                switch code {
                case .resourceExhausted:
                    throw APIError.rateLimitExceeded
                case .unauthenticated:
                    throw APIError.appCheckFailed
                default:
                    throw APIError.httpError(statusCode: error.code)
                }
            }
            throw error
        }
    }

    // MARK: - Review Generation

    func generateReviewPhase2(
        artistName: String,
        albumTitle: String,
        releaseYear: String,
        genres: [String],
        recordLabel: String,
        searchEnabled: Bool = false
    ) async throws -> Phase2Response {
        #if DEBUG
        print("🔑 [CloudFunctions Review] Starting review generation...")
        print("🔍 [AlbumScan Ultra] Search enabled: \(searchEnabled)")
        #endif

        // Choose prompt based on Ultra toggle
        let selectedPrompt = searchEnabled ? reviewUltraPrompt : reviewPrompt

        // Build prompt with album data
        let genresString = genres.joined(separator: ", ")
        let prompt = selectedPrompt
            .replacingOccurrences(of: "{artistName}", with: artistName)
            .replacingOccurrences(of: "{albumTitle}", with: albumTitle)
            .replacingOccurrences(of: "{releaseYear}", with: releaseYear)
            .replacingOccurrences(of: "{genres}", with: genresString)
            .replacingOccurrences(of: "{recordLabel}", with: recordLabel)

        // Prepare data for Cloud Function
        let data: [String: Any] = [
            "prompt": prompt,
            "useSearch": searchEnabled
        ]

        #if DEBUG
        print("📡 [CloudFunctions Review] Calling generateReview function...")
        #endif

        do {
            let result = try await functions.httpsCallable("generateReview").call(data)

            guard let resultData = result.data as? [String: Any],
                  let success = resultData["success"] as? Bool,
                  success,
                  let openAIData = resultData["data"] as? [String: Any] else {
                throw APIError.invalidResponse
            }

            #if DEBUG
            print("📡 [CloudFunctions Review] Received response")
            #endif

            return try parsePhase2Response(from: openAIData)

        } catch let error as NSError {
            #if DEBUG
            print("❌ [CloudFunctions Review] Error: \(error.localizedDescription)")
            #endif

            if error.domain == FunctionsErrorDomain {
                let code = FunctionsErrorCode(rawValue: error.code)
                switch code {
                case .resourceExhausted:
                    throw APIError.rateLimitExceeded
                case .unauthenticated:
                    throw APIError.appCheckFailed
                default:
                    throw APIError.httpError(statusCode: error.code)
                }
            }
            throw error
        }
    }

    // MARK: - LLMService Protocol Compliance (deprecated methods)

    func executePhase1A(image: UIImage) async throws -> Phase1AResponse {
        fatalError("executePhase1A is deprecated. Use executeSinglePromptIdentification instead.")
    }

    func executePhase1B(phase1AData: Phase1AResponse) async throws -> Phase1Response {
        fatalError("executePhase1B is deprecated.")
    }

    // MARK: - Response Parsers

    private func parseIdentificationResponse(from openAIData: [String: Any]) throws -> AlbumIdentificationResponse {
        guard let choices = openAIData["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw APIError.invalidResponseFormat
        }

        #if DEBUG
        print("📝 [CloudFunctions] Raw response:\n\(content)")
        #endif

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
            #if DEBUG
            print("✅ [CloudFunctions] Successfully parsed identification response")
            #endif
            return response
        } catch {
            #if DEBUG
            print("❌ [CloudFunctions] JSON parsing error: \(error)")
            #endif
            throw APIError.invalidResponseFormat
        }
    }

    private func parsePhase2Response(from openAIData: [String: Any]) throws -> Phase2Response {
        guard let choices = openAIData["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw APIError.invalidResponseFormat
        }

        #if DEBUG
        print("📝 [CloudFunctions Review] Raw response:\n\(content)")
        #endif

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
            let phase2Response = try JSONDecoder().decode(Phase2Response.self, from: jsonData)
            #if DEBUG
            print("✅ [CloudFunctions Review] Successfully parsed")
            #endif
            return phase2Response
        } catch {
            #if DEBUG
            print("❌ [CloudFunctions Review] JSON parsing error: \(error)")
            #endif
            throw APIError.invalidResponseFormat
        }
    }

    // MARK: - Helper Methods

    private func convertImageToBase64(_ image: UIImage) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.6) else {
            return nil
        }
        return imageData.base64EncodedString()
    }
}

// MARK: - Additional API Errors

extension APIError {
    static let rateLimitExceeded = APIError.httpError(statusCode: 429)
    static let appCheckFailed = APIError.httpError(statusCode: 401)
    static let invalidRequest = APIError.httpError(statusCode: 400)
}
