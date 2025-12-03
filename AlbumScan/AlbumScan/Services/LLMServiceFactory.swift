import Foundation

/// Factory class that provides the correct LLM service based on configuration
/// Switch between providers by changing Config.currentProvider
class LLMServiceFactory {
    /// Returns the configured LLM service provider
    /// - Returns: LLMService instance based on Config.currentProvider
    static func getService() -> LLMService {
        switch Config.currentProvider {
        case .cloudFunctions:
            #if DEBUG
            print("🔧 [LLMServiceFactory] Using Cloud Functions (secure proxy)")
            #endif
            return CloudFunctionsService.shared
        case .claude:
            #if DEBUG
            print("🔧 [LLMServiceFactory] Using Claude API (direct)")
            #endif
            return ClaudeAPIService.shared
        case .openAI:
            #if DEBUG
            print("🔧 [LLMServiceFactory] Using OpenAI API (direct)")
            #endif
            return OpenAIAPIService.shared
        }
    }
}
