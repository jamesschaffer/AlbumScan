import Foundation
import Combine

/// Manages free scan limit tracking using UserDefaults + Keychain
/// - UserDefaults: Primary storage (fast, ephemeral)
/// - Keychain: Backup storage (survives app reinstall)
class ScanLimitManager: ObservableObject {

    static let shared = ScanLimitManager()

    // MARK: - Published Properties

    @Published private(set) var remainingFreeScans: Int = 10
    @Published private(set) var totalScansUsed: Int = 0

    // MARK: - Constants

    private let freeScanLimit = 10
    private let userDefaultsKey = "scanCount"
    private let keychainKey = "scanCountBackup"

    // MARK: - Initialization

    private init() {
        loadScanCount()

        #if DEBUG
        print("📊 [ScanLimit] Initialized - \(remainingFreeScans) free scans remaining")
        #endif
    }

    // MARK: - Public Methods

    /// Check if user can perform a scan
    /// - Parameter isSubscribed: Whether user has active subscription
    /// - Returns: True if scan is allowed
    func canScan(isSubscribed: Bool) -> Bool {
        if isSubscribed {
            #if DEBUG
            print("✅ [ScanLimit] Can scan - user is subscribed")
            #endif
            return true
        }

        let canScan = remainingFreeScans > 0

        #if DEBUG
        if canScan {
            print("✅ [ScanLimit] Can scan - \(remainingFreeScans) free scans remaining")
        } else {
            print("⛔ [ScanLimit] Cannot scan - free limit exhausted")
        }
        #endif

        return canScan
    }

    /// Increment scan count after successful scan
    /// Only call this AFTER a scan completes successfully
    func incrementScanCount() {
        totalScansUsed += 1
        remainingFreeScans = max(0, freeScanLimit - totalScansUsed)

        saveScanCount()

        #if DEBUG
        print("📊 [ScanLimit] Incremented - \(remainingFreeScans) free scans remaining")
        #endif
    }

    /// Get human-readable status string
    func getStatusText() -> String {
        if remainingFreeScans > 0 {
            return "\(remainingFreeScans) free scan\(remainingFreeScans == 1 ? "" : "s") remaining"
        } else {
            return "Free scans exhausted"
        }
    }

    // MARK: - Private Methods

    private func loadScanCount() {
        // Try UserDefaults first (primary source)
        if let savedCount = UserDefaults.standard.value(forKey: userDefaultsKey) as? Int {
            totalScansUsed = savedCount
            #if DEBUG
            print("📊 [ScanLimit] Loaded from UserDefaults: \(totalScansUsed) scans used")
            #endif
        }
        // If UserDefaults is empty, try Keychain (reinstall scenario)
        else if let keychainCount = KeychainHelper.shared.getInt(forKey: keychainKey) {
            totalScansUsed = keychainCount
            #if DEBUG
            print("📊 [ScanLimit] Restored from Keychain: \(totalScansUsed) scans used (app was reinstalled)")
            #endif
            // Save to UserDefaults for future fast access
            UserDefaults.standard.set(totalScansUsed, forKey: userDefaultsKey)
        }
        // New user - both empty
        else {
            totalScansUsed = 0
            #if DEBUG
            print("📊 [ScanLimit] New user - 0 scans used")
            #endif
        }

        // Calculate remaining
        remainingFreeScans = max(0, freeScanLimit - totalScansUsed)
    }

    private func saveScanCount() {
        // Save to both UserDefaults and Keychain
        UserDefaults.standard.set(totalScansUsed, forKey: userDefaultsKey)
        _ = KeychainHelper.shared.save(totalScansUsed, forKey: keychainKey)

        #if DEBUG
        print("💾 [ScanLimit] Saved count: \(totalScansUsed)")
        #endif
    }

    // MARK: - Testing/Debug Methods

    #if DEBUG
    /// Reset scan count for testing (Debug only)
    func resetForTesting() {
        totalScansUsed = 0
        remainingFreeScans = freeScanLimit

        // Clear from storage
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        KeychainHelper.shared.delete(forKey: keychainKey)

        print("🔄 [ScanLimit] RESET for testing - \(freeScanLimit) free scans available")
    }

    /// Simulate subscription becoming active (Testing only)
    func simulateSubscription() {
        print("💳 [ScanLimit] Simulating active subscription - unlimited scans")
    }
    #endif
}
