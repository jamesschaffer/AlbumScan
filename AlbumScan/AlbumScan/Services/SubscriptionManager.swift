import Foundation
import StoreKit
import Combine

/// Manages in-app purchase using StoreKit 2
/// Handles purchase, restoration, and subscription status checking
@MainActor
class SubscriptionManager: ObservableObject {

    static let shared = SubscriptionManager()

    // MARK: - Published Properties

    @Published private(set) var isSubscribed: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var availableProduct: Product?
    @Published var errorMessage: String?
    @Published private(set) var productsLoadFailed: Bool = false
    @Published private(set) var hasAttemptedLoad: Bool = false

    // MARK: - Constants

    static let productID = "albumscan_ultra_annual"    // $4.99/year - single purchase option (full features)

    // Keychain key for subscription status
    // NOTE: Legacy key "subscriptionTier" may exist in user Keychains from v1.x (two-tier model).
    // It stores tier strings like "base", "ultra", "none". We no longer read it but existing
    // users may still have it. The new key below supersedes it with a simple boolean approach.
    private let keychainActiveKey = "subscriptionActive"

    // MARK: - Private Properties

    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Initialization

    private init() {
        #if DEBUG
        let initStartTime = Date()
        print("⏱️ [TIMING] SubscriptionManager init started at \(initStartTime.timeIntervalSince1970)")
        #endif

        // Load saved subscription status from Keychain
        loadSubscriptionStatus()

        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()

        #if DEBUG
        print("💳 [Subscription] Manager initialized")
        let initDuration = Date().timeIntervalSince(initStartTime) * 1000
        print("⏱️ [TIMING] Manager init completed in \(String(format: "%.2f", initDuration))ms")
        #endif

        // Check current subscription status
        // IMPORTANT: Load products FIRST so UI has pricing data
        Task {
            #if DEBUG
            let taskStartTime = Date()
            print("⏱️ [TIMING] Starting background tasks (loadProducts + checkStatus)")
            #endif

            // Load products first - this is fast and UI needs them
            await loadProducts()

            #if DEBUG
            let afterLoadTime = Date()
            print("⏱️ [TIMING] loadProducts completed in \(String(format: "%.2f", afterLoadTime.timeIntervalSince(taskStartTime)))s")
            #endif

            // Check subscription status second - this is slower but can happen in background
            await checkSubscriptionStatus()

            #if DEBUG
            let afterStatusTime = Date()
            print("⏱️ [TIMING] checkSubscriptionStatus completed in \(String(format: "%.2f", afterStatusTime.timeIntervalSince(afterLoadTime)))s")
            print("⏱️ [TIMING] Total initialization time: \(String(format: "%.2f", afterStatusTime.timeIntervalSince(initStartTime)))s")
            #endif
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Public Methods

    /// Load available product from App Store
    /// Implements retry logic with exponential backoff (3 attempts max)
    func loadProducts() async {
        #if DEBUG
        let loadStartTime = Date()
        print("⏱️ [TIMING] Starting product load at \(loadStartTime.timeIntervalSince1970)")
        #endif

        isLoading = true
        errorMessage = nil
        productsLoadFailed = false
        hasAttemptedLoad = true

        // Add timeout of 30 seconds
        let timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
            if isLoading {
                #if DEBUG
                print("⏱️ [Subscription] Load timeout after 30 seconds")
                #endif
            }
        }

        // Retry logic: 3 attempts with exponential backoff
        let maxAttempts = 3

        for attempt in 1...maxAttempts {
            do {
                #if DEBUG
                if attempt > 1 {
                    print("🔄 [Subscription] Retry attempt \(attempt) of \(maxAttempts)")
                }
                let beforeFetchTime = Date()
                print("⏱️ [TIMING] Calling Product.products() (attempt \(attempt)) after \(String(format: "%.2f", beforeFetchTime.timeIntervalSince(loadStartTime) * 1000))ms")
                #endif

                let products = try await Product.products(for: [Self.productID])

                // Cancel timeout if we got a response
                timeoutTask.cancel()

                #if DEBUG
                let afterFetchTime = Date()
                let fetchDuration = afterFetchTime.timeIntervalSince(beforeFetchTime)
                print("⏱️ [TIMING] Product.products() completed in \(String(format: "%.2f", fetchDuration))s")
                print("📦 [Subscription] Loaded \(products.count) products")
                #endif

                if let product = products.first {
                    availableProduct = product
                    #if DEBUG
                    print("✅ [Subscription] Product loaded: \(product.displayName) - \(product.displayPrice)")
                    #endif
                }

                if availableProduct == nil {
                    productsLoadFailed = true
                    errorMessage = "Product is not available. Please try again later."
                    #if DEBUG
                    print("⚠️ [Subscription] Product not found")
                    #endif
                }

                // Success - exit retry loop
                isLoading = false
                return

            } catch {
                timeoutTask.cancel()

                #if DEBUG
                print("❌ [Subscription] Load error (attempt \(attempt)): \(error)")
                print("   Error details: \(error.localizedDescription)")
                #endif

                // If this was the last attempt, set error state
                if attempt == maxAttempts {
                    productsLoadFailed = true
                    errorMessage = "Unable to connect to the App Store. Please check your connection and try again."
                    #if DEBUG
                    print("❌ [Subscription] All \(maxAttempts) attempts failed")
                    #endif
                } else {
                    // Exponential backoff: 2s for attempt 2, 4s for attempt 3
                    let backoffSeconds = Double(attempt * 2)
                    #if DEBUG
                    print("⏱️ [Subscription] Waiting \(backoffSeconds)s before retry...")
                    #endif
                    try? await Task.sleep(nanoseconds: UInt64(backoffSeconds * 1_000_000_000))
                }
            }
        }

        isLoading = false
    }

    /// Purchase the app
    func purchase() async throws {
        guard let product = availableProduct else {
            #if DEBUG
            print("❌ [Subscription] Product not available")
            #endif
            throw SubscriptionError.productNotAvailable
        }

        // Note: Don't set isLoading here - it's for product loading only
        // The view tracks purchase state with isPurchasing
        errorMessage = nil

        #if DEBUG
        print("💳 [Subscription] Starting purchase...")
        print("   Product: \(product.displayName) - \(product.displayPrice)")
        let purchaseCallStart = Date()
        print("⏱️ [TIMING] About to call Product.purchase() at \(purchaseCallStart.timeIntervalSince1970)")
        #endif

        do {
            let result = try await product.purchase()

            #if DEBUG
            let purchaseCallEnd = Date()
            let purchaseCallDuration = purchaseCallEnd.timeIntervalSince(purchaseCallStart)
            print("⏱️ [TIMING] Product.purchase() returned after \(String(format: "%.2f", purchaseCallDuration))s")
            #endif

            switch result {
            case .success(let verification):
                // Verify the transaction
                let transaction = try checkVerified(verification)

                // Update subscription status - force refresh since we just purchased
                await checkSubscriptionStatus(forceRefresh: true)

                // Finish the transaction
                await transaction.finish()

                #if DEBUG
                print("✅ [Subscription] Purchase successful")
                #endif

            case .userCancelled:
                #if DEBUG
                print("⚠️ [Subscription] User cancelled purchase")
                #endif
                throw SubscriptionError.userCancelled

            case .pending:
                #if DEBUG
                print("⏳ [Subscription] Purchase pending (Ask to Buy)")
                #endif
                throw SubscriptionError.purchasePending

            @unknown default:
                #if DEBUG
                print("❌ [Subscription] Unknown purchase result")
                #endif
                throw SubscriptionError.unknown
            }
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("❌ [Subscription] Purchase error: \(error)")
            #endif
            throw error
        }
    }

    /// Restore previous purchases
    func restorePurchases() async throws {
        isLoading = true
        errorMessage = nil

        // Ensure isLoading is reset even if an error is thrown
        defer {
            isLoading = false
        }

        #if DEBUG
        print("🔄 [Subscription] Restoring purchases...")
        #endif

        do {
            try await AppStore.sync()
            await checkSubscriptionStatus(forceRefresh: true)  // Force refresh when restoring

            if isSubscribed {
                #if DEBUG
                print("✅ [Subscription] Purchases restored")
                #endif
            } else {
                #if DEBUG
                print("⚠️ [Subscription] No active subscription found")
                #endif
                throw SubscriptionError.noActiveSubscription
            }
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("❌ [Subscription] Restore error: \(error)")
            #endif
            throw error
        }
    }

    /// Check current subscription status
    /// - Parameter forceRefresh: If true, will overwrite cache even if no subscription found (for restore purchases)
    func checkSubscriptionStatus(forceRefresh: Bool = false) async {
        #if DEBUG
        let checkStart = Date()
        print("⏱️ [TIMING] checkSubscriptionStatus: Starting entitlements check (forceRefresh: \(forceRefresh))")
        var entitlementCount = 0
        #endif

        var foundSubscription = false

        // Check for active subscription entitlements
        // Add timeout to prevent hanging
        let timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            #if DEBUG
            if !Task.isCancelled {
                print("⏱️ [TIMING] checkSubscriptionStatus: Timeout after 3 seconds")
            }
            #endif
        }

        for await result in Transaction.currentEntitlements {
            timeoutTask.cancel() // Cancel timeout if we get results
            #if DEBUG
            entitlementCount += 1
            print("⏱️ [TIMING] checkSubscriptionStatus: Processing entitlement #\(entitlementCount)")
            #endif

            do {
                let transaction = try checkVerified(result)

                // Check if our product is active
                if transaction.productID == Self.productID {
                    foundSubscription = true
                    #if DEBUG
                    print("✅ [Subscription] Active subscription found")
                    print("   Product: \(transaction.productID)")
                    print("   Purchase Date: \(transaction.purchaseDate)")
                    if let expirationDate = transaction.expirationDate {
                        print("   Expires: \(expirationDate)")
                    }
                    #endif
                    break
                }
            } catch {
                #if DEBUG
                print("❌ [Subscription] Transaction verification failed: \(error)")
                #endif
            }
        }

        // Cancel timeout task now that loop completed
        timeoutTask.cancel()

        // Save subscription status to Keychain if it changed
        // IMPORTANT: Only overwrite cache if we found an ACTUAL subscription
        // Don't overwrite to false unless forceRefresh=true (restore purchases)
        // (protects against sandbox/entitlements quirks)
        if foundSubscription && !isSubscribed {
            // New subscription found - save it
            saveSubscriptionStatus(true)
            #if DEBUG
            print("📝 [Subscription] Status changed: not subscribed → subscribed")
            #endif
        } else if !foundSubscription && isSubscribed && forceRefresh {
            // User explicitly ran restore and no subscription found - clear cache
            saveSubscriptionStatus(false)
            #if DEBUG
            print("📝 [Subscription] Force refresh: Clearing cached subscription")
            #endif
        } else if !foundSubscription && isSubscribed {
            // Background check found nothing but cache says subscribed - keep cache
            #if DEBUG
            print("⚠️ [Subscription] Status check found no subscription, but cache shows subscribed")
            print("   Keeping cached status. Run restore purchases to force refresh.")
            #endif
        }

        #if DEBUG
        let checkEnd = Date()
        let checkDuration = checkEnd.timeIntervalSince(checkStart)
        print("⏱️ [TIMING] checkSubscriptionStatus: Completed in \(String(format: "%.2f", checkDuration))s")
        print("⏱️ [TIMING] checkSubscriptionStatus: Processed \(entitlementCount) entitlements")
        if !isSubscribed {
            print("⚠️ [Subscription] No active subscription")
        }
        #endif
    }

    // MARK: - Private Methods

    /// Listen for transaction updates (new purchases, renewals, etc.)
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)

                    // Update subscription status on main actor - force refresh for transaction updates
                    await self.checkSubscriptionStatus(forceRefresh: true)

                    // Finish the transaction
                    await transaction.finish()

                    #if DEBUG
                    print("🔄 [Subscription] Transaction updated: \(transaction.productID)")
                    #endif
                } catch {
                    #if DEBUG
                    print("❌ [Subscription] Transaction update failed: \(error)")
                    #endif
                }
            }
        }
    }

    /// Verify transaction authenticity
    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Subscription Status Management

    /// Load subscription status from Keychain
    private func loadSubscriptionStatus() {
        if let statusString = KeychainHelper.shared.getString(forKey: keychainActiveKey),
           statusString == "true" {
            self.isSubscribed = true
            #if DEBUG
            print("💳 [Subscription] Loaded status from Keychain: subscribed")
            #endif
        } else {
            self.isSubscribed = false
            #if DEBUG
            print("💳 [Subscription] No status in Keychain, defaulting to not subscribed")
            #endif
        }
    }

    /// Save subscription status to Keychain
    private func saveSubscriptionStatus(_ subscribed: Bool) {
        _ = KeychainHelper.shared.save(subscribed ? "true" : "false", forKey: keychainActiveKey)
        self.isSubscribed = subscribed

        #if DEBUG
        print("💾 [Subscription] Saved status to Keychain: \(subscribed ? "subscribed" : "not subscribed")")
        #endif
    }

    // MARK: - Debug Methods

    #if DEBUG
    /// Force refresh subscription status (Debug only)
    func debugRefreshStatus() async {
        print("🔄 [Subscription] Debug: Force refreshing status...")
        await checkSubscriptionStatus(forceRefresh: true)
    }

    /// Simulate subscription for UI testing (Debug only)
    func debugSimulateSubscription() {
        print("💳 [Subscription] Debug: Simulating active subscription")
        isSubscribed = true
    }

    /// Set subscription status for testing (Debug only)
    func debugSetSubscribed(_ subscribed: Bool) {
        saveSubscriptionStatus(subscribed)
        print("🔧 [Subscription] Debug: Set isSubscribed = \(subscribed)")
    }

    /// Clear subscription status for testing (Debug only)
    func debugClearSubscription() {
        KeychainHelper.shared.delete(forKey: keychainActiveKey)
        isSubscribed = false
        print("🗑️ [Subscription] Debug: Cleared subscription from Keychain")
    }

    /// Print current subscription state (Debug only)
    func debugPrintState() {
        print("📊 [Subscription] Debug State:")
        print("   - isSubscribed: \(isSubscribed)")
        print("   - availableProduct: \(availableProduct?.displayName ?? "none")")
    }
    #endif
}

// MARK: - Errors

enum SubscriptionError: LocalizedError {
    case productNotAvailable
    case userCancelled
    case purchasePending
    case failedVerification
    case noActiveSubscription
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotAvailable:
            return "Subscription not available. Please try again later."
        case .userCancelled:
            return "Purchase cancelled"
        case .purchasePending:
            return "Purchase is pending approval"
        case .failedVerification:
            return "Purchase verification failed"
        case .noActiveSubscription:
            return "No active subscription found"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
