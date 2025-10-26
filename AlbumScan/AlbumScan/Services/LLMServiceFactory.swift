import Foundation

/// Factory class that provides the correct LLM service based on configuration
/// Switch between Claude and OpenAI by changing Config.currentProvider
class LLMServiceFactory {
    /// Returns the configured LLM service provider
    /// - Returns: LLMService instance (ClaudeAPIService or OpenAIAPIService)
    static func getService() -> LLMService {
        switch Config.currentProvider {
        case .claude:
            print("🔧 [LLMServiceFactory] Using Claude API")
            return ClaudeAPIService.shared
        case .openAI:
            print("🔧 [LLMServiceFactory] Using OpenAI API")
            return OpenAIAPIService.shared
        }
    }
}
