import Foundation
import FirebaseCore
import FirebaseRemoteConfig
import Combine

/// Manages Firebase Remote Config for remote kill switch and feature flags
/// Provides emergency controls without requiring app update
@MainActor
class RemoteConfigManager: ObservableObject {

    static let shared = RemoteConfigManager()

    // MARK: - Published Properties

    @Published private(set) var scanningEnabled: Bool = true
    @Published private(set) var freeScanLimit: Int = 5
    @Published private(set) var maintenanceMessage: String = ""
    @Published private(set) var isConfigLoaded: Bool = false

    // MARK: - Private Properties

    private var remoteConfig: RemoteConfig

    // MARK: - Config Keys

    private enum ConfigKey: String {
        case scanningEnabled = "scanning_enabled"
        case freeScanLimit = "free_scan_limit"
        case maintenanceMessage = "maintenance_message"
    }

    // MARK: - Initialization

    private init() {
        // Initialize Remote Config
        remoteConfig = RemoteConfig.remoteConfig()

        // Set config settings
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 3600 // 1 hour in production
        #if DEBUG
        settings.minimumFetchInterval = 0 // No throttling in debug
        #endif
        remoteConfig.configSettings = settings

        // Set default values (used if Firebase is unreachable)
        setDefaultValues()

        #if DEBUG
        print("🔧 [RemoteConfig] Manager initialized with defaults")
        #endif
    }

    // MARK: - Public Methods

    /// Initialize Firebase and fetch remote config
    /// Call this once at app launch
    func initialize() {
        // Configure Firebase
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            #if DEBUG
            print("🔥 [Firebase] Configured successfully")
            #endif
        }

        // Fetch config asynchronously
        Task {
            await fetchConfig()
        }
    }

    /// Fetch and activate remote config from Firebase
    func fetchConfig() async {
        #if DEBUG
        print("🔧 [RemoteConfig] Fetching configuration...")
        #endif

        do {
            let status = try await remoteConfig.fetch()

            #if DEBUG
            print("🔧 [RemoteConfig] Fetch status: \(status)")
            #endif

            let activated = try await remoteConfig.activate()

            #if DEBUG
            print("🔧 [RemoteConfig] Activated: \(activated)")
            #endif

            // Update local values
            await updateLocalValues()

            isConfigLoaded = true

            #if DEBUG
            print("✅ [RemoteConfig] Configuration loaded successfully")
            print("   Scanning Enabled: \(scanningEnabled)")
            print("   Free Scan Limit: \(freeScanLimit)")
            print("   Maintenance Message: \(maintenanceMessage.isEmpty ? "(none)" : maintenanceMessage)")
            #endif

        } catch {
            #if DEBUG
            print("⚠️ [RemoteConfig] Fetch failed: \(error.localizedDescription)")
            print("   Using default values")
            #endif

            // Use defaults on error (graceful degradation)
            isConfigLoaded = true
        }
    }

    /// Force refresh config (for testing or manual refresh)
    func forceRefresh() async {
        await fetchConfig()
    }

    // MARK: - Private Methods

    private func setDefaultValues() {
        let defaults: [String: NSObject] = [
            ConfigKey.scanningEnabled.rawValue: true as NSObject,
            ConfigKey.freeScanLimit.rawValue: 5 as NSObject,
            ConfigKey.maintenanceMessage.rawValue: "" as NSObject
        ]

        remoteConfig.setDefaults(defaults)

        #if DEBUG
        print("🔧 [RemoteConfig] Default values set")
        #endif
    }

    private func updateLocalValues() async {
        scanningEnabled = remoteConfig[ConfigKey.scanningEnabled.rawValue].boolValue
        freeScanLimit = remoteConfig[ConfigKey.freeScanLimit.rawValue].numberValue.intValue
        maintenanceMessage = remoteConfig[ConfigKey.maintenanceMessage.rawValue].stringValue
    }

    // MARK: - Debug Methods

    #if DEBUG
    /// Simulate kill switch for testing
    func debugSimulateKillSwitch() {
        print("🔴 [RemoteConfig] Debug: Simulating kill switch")
        scanningEnabled = false
        maintenanceMessage = "App is temporarily unavailable for maintenance. Please try again later."
    }

    /// Reset to normal operation
    func debugResetKillSwitch() {
        print("✅ [RemoteConfig] Debug: Resetting kill switch")
        scanningEnabled = true
        maintenanceMessage = ""
    }

    /// Simulate changing free scan limit
    func debugSetFreeScanLimit(_ limit: Int) {
        print("🔧 [RemoteConfig] Debug: Setting free scan limit to \(limit)")
        freeScanLimit = limit
    }
    #endif
}
