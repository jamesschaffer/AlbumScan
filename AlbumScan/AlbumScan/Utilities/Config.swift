import Foundation

enum Config {
    // MARK: - API Configuration

    static var claudeAPIKey: String {
        // First try to get from environment variable
        if let envKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"], !envKey.isEmpty {
            return envKey
        }

        // TODO: Add additional secure storage methods
        // - Keychain
        // - Build configuration file
        // - Secrets.plist (gitignored)

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
