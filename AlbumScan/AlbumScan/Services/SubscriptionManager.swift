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
        // Load saved subscription tier from Keychain
        loadSubscriptionTier()

        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()

        #if DEBUG
        print("💳 [Subscription] Manager initialized")
        #endif

        // Check current subscription status
        Task {
            await checkSubscriptionStatus()
            await loadProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Public Methods

    /// Load available subscription products from App Store
    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let products = try await Product.products(for: [Self.baseProductID, Self.ultraProductID])

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
                errorMessage = "Some subscription products not available"
                #if DEBUG
                print("⚠️ [Subscription] Missing products - Base: \(availableBaseProduct != nil), Ultra: \(availableUltraProduct != nil)")
                #endif
            }
        } catch {
            errorMessage = "Failed to load subscriptions: \(error.localizedDescription)"
            #if DEBUG
            print("❌ [Subscription] Load error: \(error)")
            #endif
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

        isLoading = true
        errorMessage = nil

        #if DEBUG
        print("💳 [Subscription] Starting purchase for \(tier.rawValue)...")
        print("   Product: \(selectedProduct.displayName) - \(selectedProduct.displayPrice)")
        #endif

        do {
            let result = try await selectedProduct.purchase()

            switch result {
            case .success(let verification):
                // Verify the transaction
                let transaction = try checkVerified(verification)

                // Update subscription status
                await checkSubscriptionStatus()

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

        isLoading = false
    }

    /// Restore previous purchases
    func restorePurchases() async throws {
        isLoading = true
        errorMessage = nil

        #if DEBUG
        print("🔄 [Subscription] Restoring purchases...")
        #endif

        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()

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

        isLoading = false
    }

    /// Check current subscription status
    func checkSubscriptionStatus() async {
        var detectedTier: SubscriptionTier = .none

        // Check for active subscription entitlements
        for await result in Transaction.currentEntitlements {
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

        // Update subscription state
        isSubscribed = (detectedTier != .none)

        // Save detected tier to Keychain if it changed
        if detectedTier != subscriptionTier {
            saveSubscriptionTier(detectedTier)
            #if DEBUG
            print("📝 [Subscription] Tier changed: \(subscriptionTier.rawValue) → \(detectedTier.rawValue)")
            #endif
        } else {
            subscriptionTier = detectedTier
        }

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

                    // Update subscription status on main actor
                    await self.checkSubscriptionStatus()

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
        await checkSubscriptionStatus()
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
