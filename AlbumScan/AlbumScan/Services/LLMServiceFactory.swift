import Foundation

/// Factory class that provides the correct LLM service based on configuration
/// In production, always uses CloudFunctionsService (secure proxy)
/// In debug mode, supports provider switching via AppState.selectedProvider
class LLMServiceFactory {
    /// Returns the configured LLM service provider
    /// - Parameter provider: Optional provider override (debug only). Uses default routing if nil.
    /// - Returns: LLMService instance configured for the appropriate provider
    static func getService(for provider: LLMProvider? = nil) -> LLMService {
        #if DEBUG
        // In debug mode, route through CloudFunctionsService with dynamic provider
        let selectedProvider = provider ?? .openAI
        let service = CloudFunctionsService.shared
        service.currentProvider = selectedProvider
        print("🔧 [LLMServiceFactory] Using Cloud Functions with provider: \(selectedProvider.displayName)")
        return service
        #else
        // Production: Always use CloudFunctionsService with OpenAI
        switch Config.currentProvider {
        case .cloudFunctions, .openAI, .gemini:
            return CloudFunctionsService.shared
        case .claude:
            return ClaudeAPIService.shared
        }
        #endif
    }
}
