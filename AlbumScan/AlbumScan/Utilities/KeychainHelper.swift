import Foundation
import Security

/// Secure storage helper using iOS Keychain
/// Persists data even after app deletion (for legitimate reinstall recovery)
class KeychainHelper {

    static let shared = KeychainHelper()

    private init() {}

    /// Save an integer value to Keychain
    func save(_ value: Int, forKey key: String) -> Bool {
        // Convert Int to Data
        let data = withUnsafeBytes(of: value) { Data($0) }
        return save(data, forKey: key)
    }

    /// Retrieve an integer value from Keychain
    func getInt(forKey key: String) -> Int? {
        guard let data = get(forKey: key), data.count == MemoryLayout<Int>.size else {
            return nil
        }
        return data.withUnsafeBytes { $0.load(as: Int.self) }
    }

    /// Save a string value to Keychain
    func save(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            return false
        }
        return save(data, forKey: key)
    }

    /// Retrieve a string value from Keychain
    func getString(forKey key: String) -> String? {
        guard let data = get(forKey: key),
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }

    /// Save data to Keychain
    func save(_ data: Data, forKey key: String) -> Bool {
        // Delete any existing item first
        delete(forKey: key)

        // Create query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "jamesschaffer.AlbumScan",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        // Add to Keychain
        let status = SecItemAdd(query as CFDictionary, nil)

        #if DEBUG
        if status == errSecSuccess {
            print("✅ [Keychain] Saved: \(key)")
        } else {
            print("❌ [Keychain] Save failed for \(key): \(status)")
        }
        #endif

        return status == errSecSuccess
    }

    /// Retrieve data from Keychain
    func get(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "jamesschaffer.AlbumScan",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            #if DEBUG
            if status != errSecItemNotFound {
                print("❌ [Keychain] Get failed for \(key): \(status)")
            }
            #endif
            return nil
        }

        return data
    }

    /// Delete a value from Keychain
    @discardableResult
    func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "jamesschaffer.AlbumScan"
        ]

        let status = SecItemDelete(query as CFDictionary)

        // errSecItemNotFound is not an error (item didn't exist)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    /// Clear all Keychain items for this app (testing only)
    func clearAll() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "jamesschaffer.AlbumScan"
        ]

        let status = SecItemDelete(query as CFDictionary)

        #if DEBUG
        print("🗑️ [Keychain] Cleared all items")
        #endif

        return status == errSecSuccess || status == errSecItemNotFound
    }
}
