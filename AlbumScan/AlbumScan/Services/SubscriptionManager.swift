import Foundation
import StoreKit
import Combine

/// Subscription tier options
enum SubscriptionTier: String, Codable {
    case none = "none"           // No active subscription
    case base = "base"           // Base plan: $4.99/year, ID Call 1 only
    case ultra = "ultra"         // Ultra plan: $11.99/year, full two-tier with search
}

/// Manages in-app subscription using StoreKit 2
/// Handles purchase, restoration, and subscription status checking
@MainActor
class SubscriptionManager: ObservableObject {

    static let shared = SubscriptionManager()

    // MARK: - Published Properties

    @Published private(set) var isSubscribed: Bool = false
    @Published private(set) var subscriptionTier: SubscriptionTier = .none
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var availableBaseProduct: Product?
    @Published private(set) var availableUltraProduct: Product?
    @Published var errorMessage: String?
    @Published private(set) var productsLoadFailed: Bool = false
    @Published private(set) var hasAttemptedLoad: Bool = false

    // MARK: - Constants

    static let baseProductID = "albumscan_base_annual"      // $4.99/year
    static let ultraProductID = "albumscan_ultra_annual"    // $11.99/year

    // Keychain keys for subscription tier tracking
    private let keychainTierKey = "subscriptionTier"
    private let keychainActiveKey = "subscriptionActive"

    // MARK: - Private Properties

    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Initialization

    private init() {
        let initStartTime = Date()
        print("⏱️ [TIMING] SubscriptionManager init started at \(initStartTime.timeIntervalSince1970)")

        // Load saved subscription tier from Keychain
        loadSubscriptionTier()

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
            let taskStartTime = Date()
            print("⏱️ [TIMING] Starting background tasks (loadProducts + checkStatus)")

            // Load products first - this is fast and UI needs them
            await loadProducts()

            let afterLoadTime = Date()
            print("⏱️ [TIMING] loadProducts completed in \(String(format: "%.2f", afterLoadTime.timeIntervalSince(taskStartTime)))s")

            // Check subscription status second - this is slower but can happen in background
            await checkSubscriptionStatus()

            let afterStatusTime = Date()
            print("⏱️ [TIMING] checkSubscriptionStatus completed in \(String(format: "%.2f", afterStatusTime.timeIntervalSince(afterLoadTime)))s")
            print("⏱️ [TIMING] Total initialization time: \(String(format: "%.2f", afterStatusTime.timeIntervalSince(initStartTime)))s")
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Public Methods

    /// Load available subscription products from App Store
    /// Implements retry logic with exponential backoff (3 attempts max)
    func loadProducts() async {
        let loadStartTime = Date()
        print("⏱️ [TIMING] Starting product load at \(loadStartTime.timeIntervalSince1970)")

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
                #endif

                let beforeFetchTime = Date()
                print("⏱️ [TIMING] Calling Product.products() (attempt \(attempt)) after \(String(format: "%.2f", beforeFetchTime.timeIntervalSince(loadStartTime) * 1000))ms")

                let products = try await Product.products(for: [Self.baseProductID, Self.ultraProductID])

                let afterFetchTime = Date()
                let fetchDuration = afterFetchTime.timeIntervalSince(beforeFetchTime)
                print("⏱️ [TIMING] Product.products() completed in \(String(format: "%.2f", fetchDuration))s")

                // Cancel timeout if we got a response
                timeoutTask.cancel()

                #if DEBUG
                print("📦 [Subscription] Loaded \(products.count) products")
                #endif

                for product in products {
                    if product.id == Self.baseProductID {
                        availableBaseProduct = product
                        #if DEBUG
                        print("✅ [Subscription] Base loaded: \(product.displayName) - \(product.displayPrice)")
                        #endif
                    } else if product.id == Self.ultraProductID {
                        availableUltraProduct = product
                        #if DEBUG
                        print("✅ [Subscription] Ultra loaded: \(product.displayName) - \(product.displayPrice)")
                        #endif
                    }
                }

                if availableBaseProduct == nil || availableUltraProduct == nil {
                    productsLoadFailed = true
                    errorMessage = "Some subscription products are not available. Please try again later."
                    #if DEBUG
                    print("⚠️ [Subscription] Missing products - Base: \(availableBaseProduct != nil), Ultra: \(availableUltraProduct != nil)")
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

    /// Purchase a subscription tier
    func purchase(tier: SubscriptionTier) async throws {
        // Select the correct product based on tier
        let product: Product?
        switch tier {
        case .base:
            product = availableBaseProduct
        case .ultra:
            product = availableUltraProduct
        case .none:
            throw SubscriptionError.productNotAvailable
        }

        guard let selectedProduct = product else {
            #if DEBUG
            print("❌ [Subscription] Product not available for tier: \(tier.rawValue)")
            #endif
            throw SubscriptionError.productNotAvailable
        }

        // Note: Don't set isLoading here - it's for product loading only
        // The view tracks purchase state with isPurchasing
        errorMessage = nil

        #if DEBUG
        print("💳 [Subscription] Starting purchase for \(tier.rawValue)...")
        print("   Product: \(selectedProduct.displayName) - \(selectedProduct.displayPrice)")
        let purchaseCallStart = Date()
        print("⏱️ [TIMING] About to call Product.purchase() at \(purchaseCallStart.timeIntervalSince1970)")
        #endif

        do {
            let result = try await selectedProduct.purchase()

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
                print("✅ [Subscription] Purchase successful for \(tier.rawValue)")
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
        let checkStart = Date()
        print("⏱️ [TIMING] checkSubscriptionStatus: Starting entitlements check (forceRefresh: \(forceRefresh))")

        var detectedTier: SubscriptionTier = .none

        // Check for active subscription entitlements
        // Add timeout to prevent hanging
        let timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            if !Task.isCancelled {
                print("⏱️ [TIMING] checkSubscriptionStatus: Timeout after 3 seconds")
            }
        }

        var entitlementCount = 0
        for await result in Transaction.currentEntitlements {
            timeoutTask.cancel() // Cancel timeout if we get results
            entitlementCount += 1
            print("⏱️ [TIMING] checkSubscriptionStatus: Processing entitlement #\(entitlementCount)")

            do {
                let transaction = try checkVerified(result)

                // Check which subscription product is active
                if transaction.productID == Self.baseProductID {
                    detectedTier = .base
                    #if DEBUG
                    print("✅ [Subscription] Active BASE subscription found")
                    print("   Product: \(transaction.productID)")
                    print("   Purchase Date: \(transaction.purchaseDate)")
                    if let expirationDate = transaction.expirationDate {
                        print("   Expires: \(expirationDate)")
                    }
                    #endif
                    // Don't break - keep checking in case Ultra is also present (upgrade scenario)
                } else if transaction.productID == Self.ultraProductID {
                    detectedTier = .ultra
                    #if DEBUG
                    print("✅ [Subscription] Active ULTRA subscription found")
                    print("   Product: \(transaction.productID)")
                    print("   Purchase Date: \(transaction.purchaseDate)")
                    if let expirationDate = transaction.expirationDate {
                        print("   Expires: \(expirationDate)")
                    }
                    #endif
                    break // Ultra is highest tier, no need to keep checking
                }
            } catch {
                #if DEBUG
                print("❌ [Subscription] Transaction verification failed: \(error)")
                #endif
            }
        }

        // Cancel timeout task now that loop completed
        timeoutTask.cancel()

        // Update subscription state
        isSubscribed = (detectedTier != .none)

        // Save detected tier to Keychain if it changed
        // IMPORTANT: Only overwrite cache if we found an ACTUAL subscription
        // Don't overwrite to .none unless forceRefresh=true (restore purchases)
        // (protects against sandbox/entitlements quirks)
        if detectedTier != subscriptionTier {
            // If we detected a subscription (base or ultra), always save it
            if detectedTier != .none {
                saveSubscriptionTier(detectedTier)
                #if DEBUG
                print("📝 [Subscription] Tier changed: \(subscriptionTier.rawValue) → \(detectedTier.rawValue)")
                #endif
            }
            // If we detected .none but had a subscription before
            else if subscriptionTier != .none {
                if forceRefresh {
                    // User explicitly ran restore - trust the result
                    saveSubscriptionTier(.none)
                    #if DEBUG
                    print("📝 [Subscription] Force refresh: Clearing cached subscription")
                    #endif
                } else {
                    // Background check - don't overwrite cache
                    #if DEBUG
                    print("⚠️ [Subscription] Status check found no subscription, but cache shows \(subscriptionTier.rawValue)")
                    print("   Keeping cached tier. Run restore purchases to force refresh.")
                    #endif
                    // Keep the cached tier for now
                    isSubscribed = true // Trust the cache
                }
            }
            // If both are .none, no need to save
        } else {
            // No change detected, keep current tier
            subscriptionTier = detectedTier
        }

        let checkEnd = Date()
        let checkDuration = checkEnd.timeIntervalSince(checkStart)
        print("⏱️ [TIMING] checkSubscriptionStatus: Completed in \(String(format: "%.2f", checkDuration))s")
        print("⏱️ [TIMING] checkSubscriptionStatus: Processed \(entitlementCount) entitlements")

        #if DEBUG
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

    // MARK: - Subscription Tier Management

    /// Load subscription tier from Keychain
    private func loadSubscriptionTier() {
        if let tierString = KeychainHelper.shared.getString(forKey: keychainTierKey),
           let tier = SubscriptionTier(rawValue: tierString) {
            self.subscriptionTier = tier
            #if DEBUG
            print("💳 [Subscription] Loaded tier from Keychain: \(tier.rawValue)")
            #endif
        } else {
            self.subscriptionTier = .none
            #if DEBUG
            print("💳 [Subscription] No tier in Keychain, defaulting to .none")
            #endif
        }
    }

    /// Save subscription tier to Keychain
    private func saveSubscriptionTier(_ tier: SubscriptionTier) {
        _ = KeychainHelper.shared.save(tier.rawValue, forKey: keychainTierKey)
        self.subscriptionTier = tier

        #if DEBUG
        print("💾 [Subscription] Saved tier to Keychain: \(tier.rawValue)")
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

    /// Set subscription tier for testing (Debug only)
    /// - Parameter tier: The tier to set (.none, .base, or .ultra)
    func debugSetTier(_ tier: SubscriptionTier) {
        saveSubscriptionTier(tier)
        isSubscribed = (tier != .none)
        print("🔧 [Subscription] Debug: Set tier to \(tier.rawValue), isSubscribed = \(isSubscribed)")
    }

    /// Clear subscription tier for testing (Debug only)
    func debugClearTier() {
        KeychainHelper.shared.delete(forKey: keychainTierKey)
        subscriptionTier = .none
        isSubscribed = false
        print("🗑️ [Subscription] Debug: Cleared tier from Keychain")
    }

    /// Print current subscription state (Debug only)
    func debugPrintState() {
        print("📊 [Subscription] Debug State:")
        print("   - isSubscribed: \(isSubscribed)")
        print("   - subscriptionTier: \(subscriptionTier.rawValue)")
        print("   - availableBaseProduct: \(availableBaseProduct?.displayName ?? "none")")
        print("   - availableUltraProduct: \(availableUltraProduct?.displayName ?? "none")")
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
