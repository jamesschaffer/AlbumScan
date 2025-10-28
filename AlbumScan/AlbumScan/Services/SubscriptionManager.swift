import Foundation
import StoreKit
import Combine

/// Manages in-app subscription using StoreKit 2
/// Handles purchase, restoration, and subscription status checking
@MainActor
class SubscriptionManager: ObservableObject {

    static let shared = SubscriptionManager()

    // MARK: - Published Properties

    @Published private(set) var isSubscribed: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var availableProduct: Product?
    @Published var errorMessage: String?

    // MARK: - Constants

    static let productID = "albumscan_unlimited_annual"

    // MARK: - Private Properties

    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Initialization

    private init() {
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

    /// Load available subscription product from App Store
    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let products = try await Product.products(for: [Self.productID])

            if let product = products.first {
                availableProduct = product
                #if DEBUG
                print("✅ [Subscription] Product loaded: \(product.displayName) - \(product.displayPrice)")
                #endif
            } else {
                errorMessage = "Subscription product not available"
                #if DEBUG
                print("❌ [Subscription] Product not found: \(Self.productID)")
                #endif
            }
        } catch {
            errorMessage = "Failed to load subscription: \(error.localizedDescription)"
            #if DEBUG
            print("❌ [Subscription] Load error: \(error)")
            #endif
        }

        isLoading = false
    }

    /// Purchase the subscription
    func purchase() async throws {
        guard let product = availableProduct else {
            throw SubscriptionError.productNotAvailable
        }

        isLoading = true
        errorMessage = nil

        #if DEBUG
        print("💳 [Subscription] Starting purchase...")
        #endif

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify the transaction
                let transaction = try checkVerified(verification)

                // Update subscription status
                await checkSubscriptionStatus()

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
        var isCurrentlySubscribed = false

        // Check for active subscription entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Check if this is our subscription product
                if transaction.productID == Self.productID {
                    isCurrentlySubscribed = true
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

        isSubscribed = isCurrentlySubscribed

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
