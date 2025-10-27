import Foundation

/// Factory class that provides the correct LLM service based on configuration
/// Switch between Claude and OpenAI by changing Config.currentProvider
class LLMServiceFactory {
    /// Returns the configured LLM service provider
    /// - Returns: LLMService instance (ClaudeAPIService or OpenAIAPIService)
    static func getService() -> LLMService {
        switch Config.currentProvider {
        case .claude:
            #if DEBUG
            print("🔧 [LLMServiceFactory] Using Claude API")
            #endif
            return ClaudeAPIService.shared
        case .openAI:
            #if DEBUG
            print("🔧 [LLMServiceFactory] Using OpenAI API")
            #endif
            return OpenAIAPIService.shared
        }
    }
}
