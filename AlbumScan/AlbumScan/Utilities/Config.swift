import Foundation

enum Config {
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
    }
}
