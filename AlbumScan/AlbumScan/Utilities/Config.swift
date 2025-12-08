import Foundation

// MARK: - LLM Provider Selection

/// AI provider for album identification and review generation
/// User-selectable providers route through Cloud Functions with different backends
enum LLMProvider: String, CaseIterable {
    case openAI = "openai"
    case gemini = "gemini"

    // Legacy providers (not user-selectable, kept for backwards compatibility)
    case claude = "claude"
    case cloudFunctions = "cloudFunctions"

    /// Display name shown in UI
    var displayName: String {
        switch self {
        case .openAI: return "ChatGPT"
        case .gemini: return "Gemini"
        case .claude: return "Claude"
        case .cloudFunctions: return "Cloud Functions"
        }
    }

    /// Description for settings UI
    var description: String {
        switch self {
        case .openAI: return "OpenAI GPT-4o"
        case .gemini: return "Google Gemini 2.5 Flash"
        case .claude: return "Anthropic Claude (Legacy)"
        case .cloudFunctions: return "Firebase Proxy (Legacy)"
        }
    }

    /// Providers that can be selected by users in debug mode
    static var selectableProviders: [LLMProvider] {
        [.openAI, .gemini]
    }

    // Legacy compatibility
    var name: String {
        displayName
    }
}

enum Config {
    // MARK: - LLM Configuration

    /// Current LLM provider
    /// - .cloudFunctions: (RECOMMENDED) Secure server-side API calls via Firebase
    /// - .openAI: Direct API calls (API key in app bundle - NOT recommended for production)
    /// - .claude: Legacy Claude API (deprecated)
    static let currentProvider: LLMProvider = .cloudFunctions

    // MARK: - API Configuration

    static var claudeAPIKey: String {
        // First try to get from Secrets.plist (recommended for local development)
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let secrets = NSDictionary(contentsOfFile: path),
           let apiKey = secrets["CLAUDE_API_KEY"] as? String, !apiKey.isEmpty {
            return apiKey
        }

        // Fallback to environment variable (for Xcode scheme settings)
        if let envKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"], !envKey.isEmpty {
            return envKey
        }

        // If no key found, return empty (will trigger error in API service)
        return ""
    }

    static var openAIAPIKey: String {
        // First try to get from Secrets.plist (recommended for local development)
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let secrets = NSDictionary(contentsOfFile: path),
           let apiKey = secrets["OPENAI_API_KEY"] as? String, !apiKey.isEmpty {
            return apiKey
        }

        // Fallback to environment variable (for Xcode scheme settings)
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            return envKey
        }

        // If no key found, return empty (will trigger error in API service)
        return ""
    }

    // MARK: - App Configuration

    static let appName = "AlbumScan"
    static let minimumIOSVersion = "16.0"

    // MARK: - API Settings

    static let apiTimeout: TimeInterval = 10.0
    static let maxImageSize: CGFloat = 1024

    // MARK: - Image Processing

    static let jpegCompressionQuality: CGFloat = 0.8
    static let thumbnailSize: CGFloat = 200

    // MARK: - User Defaults Keys

    enum UserDefaultsKeys {
        static let hasLaunchedBefore = "hasLaunchedBefore"
        static let selectedLLMProvider = "selectedLLMProvider"
    }
}
