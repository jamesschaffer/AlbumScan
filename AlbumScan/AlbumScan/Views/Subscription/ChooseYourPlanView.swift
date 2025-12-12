import SwiftUI
import StoreKit

// MARK: - Legal URLs (Required for App Store)

/// Legal URLs for Terms of Use and Privacy Policy
/// Hosted on GitHub Pages: https://jamesschaffer.github.io/AlbumScan/
enum LegalConstants {
    /// Privacy Policy URL (required for App Store)
    static let privacyPolicyURL = "https://jamesschaffer.github.io/AlbumScan/privacy-policy.html"

    /// Terms of Use / EULA URL (custom terms of service)
    static let termsOfUseURL = "https://jamesschaffer.github.io/AlbumScan/terms-of-service.html"
}

/// Subscription component that handles purchase states
/// Shows the appropriate UI based on subscription status:
/// - Not subscribed: Shows purchase option with features
/// - Subscribed: Shows success state
struct SubscriptionCardView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    @State private var isPurchasing = false

    let onPurchaseSuccess: () -> Void
    let onError: (String) -> Void
    let onSkip: (() -> Void)? // Optional callback for "Use free scans" - only shown when provided
    let hasScansRemaining: Bool // Whether user has free scans remaining

    private let brandGreen = Color(red: 0, green: 0.87, blue: 0.32)

    // Fallback pricing when StoreKit unavailable (matches App Store price for albumscan_ultra_annual)
    private let fallbackPrice = "$4.99/year"
    private let fallbackPriceShort = "$4.99"

    // Helper computed properties for prices with fallback
    private var priceDisplay: String {
        subscriptionManager.availableProduct?.displayPrice ?? fallbackPriceShort
    }

    private var priceFullDisplay: String {
        if let product = subscriptionManager.availableProduct {
            return "\(product.displayPrice)/yr"
        }
        return fallbackPrice
    }

    // Check if the product is available
    private var isProductAvailable: Bool {
        return subscriptionManager.availableProduct != nil
    }

    // Check if products are still loading
    private var areProductsLoading: Bool {
        // Show loading if:
        // 1. Haven't attempted to load yet (initial state), OR
        // 2. Currently loading
        // This prevents showing UI with nil products
        return !subscriptionManager.hasAttemptedLoad || subscriptionManager.isLoading
    }

    // Check if products failed to load
    private var didProductsFailToLoad: Bool {
        return subscriptionManager.hasAttemptedLoad &&
               subscriptionManager.productsLoadFailed &&
               !subscriptionManager.isLoading
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Show loading state if products are loading
            if areProductsLoading {
                loadingView
                    .onAppear {
                        print("⏱️ [TIMING] Subscription view showing LOADING state")
                    }
            }
            // Show error state if products failed to load
            else if didProductsFailToLoad {
                errorView
                    .onAppear {
                        print("⏱️ [TIMING] Subscription view showing ERROR state")
                    }
            }
            // Show normal subscription UI
            else {
                if subscriptionManager.isSubscribed {
                    // Subscribed - Show success state
                    subscribedSuccessView
                } else {
                    // Not subscribed - Show purchase option
                    purchaseView
                }
            }
        }
    }

    // MARK: - Purchase View

    private var purchaseView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Get AlbumScan")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .onAppear {
                    print("⏱️ [TIMING] Subscription view READY - product loaded, UI interactive")
                    print("⏱️ [TIMING] Product: \(subscriptionManager.availableProduct?.displayName ?? "nil")")
                }

            // Features list
            VStack(alignment: .leading, spacing: 12) {
                BenefitRow(text: "One-click search, unlike clunky search engines", color: brandGreen)
                BenefitRow(text: "Reviews from credible industry experts - Pitchfork, Rolling Stone, etc.", color: brandGreen)
                BenefitRow(text: "Concise reviews that communicate album importance and context", color: brandGreen)
                BenefitRow(text: "8-tier recommendation system that identifies albums that matter", color: brandGreen)
            }
            .padding(.top, 8)

            // Purchase Button
            Button(action: handlePurchase) {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Buy AlbumScan - \(priceDisplay)")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(brandGreen)
                .cornerRadius(12)
            }
            .disabled(isPurchasing || !isProductAvailable)
            .padding(.top, 16)

            // Auto-renewal notice (required by Apple)
            Text("Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.top, 12)
                .padding(.horizontal, 8)

            // Optional "Use free scans" button or "out of scans" message
            if let skipAction = onSkip {
                Button(action: skipAction) {
                    HStack(spacing: 4) {
                        Text(hasScansRemaining ? "Use your 5 free scans" : "You have run out of free scans")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        if hasScansRemaining {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.top, 10)
            }

            // Legal links (required for App Store subscription approval)
            LegalLinksView(onError: onError)
                .padding(.top, 16)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(alignment: .center, spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: brandGreen))
                .scaleEffect(1.5)

            Text("Loading...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Subscribed Success View

    private var subscribedSuccessView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AlbumScan")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text("You have full access to AlbumScan")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(brandGreen)
                .padding(.top, 8)

            Text("To manage your subscription or cancel renewal, visit the App Store.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 4)

            #if DEBUG
            Button(action: {
                // Debug reset - reload subscription status with force refresh
                Task {
                    await subscriptionManager.checkSubscriptionStatus(forceRefresh: true)
                }
            }) {
                Text("Refresh Status (Debug)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
            }
            .padding(.top, 12)
            #endif
        }
    }

    // MARK: - Error View

    private var errorView: some View {
        VStack(alignment: .center, spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Unable to Load")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(subscriptionManager.errorMessage ?? "Could not connect to the App Store. Please check your internet connection and try again.")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Button(action: {
                Task {
                    await subscriptionManager.loadProducts()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Try Again")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(brandGreen)
                .cornerRadius(12)
            }
            .padding(.top, 8)

            // Optional skip button if provided
            if let skipAction = onSkip, hasScansRemaining {
                Button(action: skipAction) {
                    HStack(spacing: 4) {
                        Text("Use your 5 free scans")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Actions

    private func handlePurchase() {
        let buttonTapTime = Date()
        print("⏱️ [TIMING] Button tapped at \(buttonTapTime.timeIntervalSince1970)")

        isPurchasing = true

        let stateUpdateTime = Date()
        let stateUpdateDelay = stateUpdateTime.timeIntervalSince(buttonTapTime) * 1000
        print("⏱️ [TIMING] State updated after \(String(format: "%.2f", stateUpdateDelay))ms")

        Task {
            let taskStartTime = Date()
            let taskDelay = taskStartTime.timeIntervalSince(buttonTapTime) * 1000
            print("⏱️ [TIMING] Task started after \(String(format: "%.2f", taskDelay))ms from button tap")

            do {
                let beforePurchaseTime = Date()
                print("⏱️ [TIMING] Calling purchase() after \(String(format: "%.2f", beforePurchaseTime.timeIntervalSince(buttonTapTime) * 1000))ms")

                try await subscriptionManager.purchase()

                let afterPurchaseTime = Date()
                let purchaseDuration = afterPurchaseTime.timeIntervalSince(beforePurchaseTime)
                print("⏱️ [TIMING] Purchase completed in \(String(format: "%.2f", purchaseDuration))s")
                print("⏱️ [TIMING] Total time from button tap: \(String(format: "%.2f", afterPurchaseTime.timeIntervalSince(buttonTapTime)))s")

                // Success! Call success callback
                await MainActor.run {
                    isPurchasing = false
                    onPurchaseSuccess()
                }
            } catch SubscriptionError.userCancelled {
                // User cancelled - no error message needed
                await MainActor.run {
                    isPurchasing = false
                }
            } catch {
                await MainActor.run {
                    onError(error.localizedDescription)
                    isPurchasing = false
                }
            }
        }
    }
}

// MARK: - Benefit Row

struct BenefitRow: View {
    let text: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Legal Links View

/// Displays Privacy Policy, Terms of Use links, Restore Purchases, and Manage Subscription (required for App Store)
struct LegalLinksView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.openURL) var openURL
    let onError: (String) -> Void

    @State private var isRestoring = false

    var body: some View {
        VStack(spacing: 12) {
            // Legal links row
            HStack(spacing: 8) {
                // Privacy Policy link
                Link(destination: URL(string: LegalConstants.privacyPolicyURL)!) {
                    Text("Privacy Policy")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .underline()
                }

                Text("•")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))

                // Terms of Use link
                Link(destination: URL(string: LegalConstants.termsOfUseURL)!) {
                    Text("Terms of Use")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .underline()
                }
            }
            .frame(maxWidth: .infinity)

            // Action buttons row
            HStack(spacing: 16) {
                // Restore Purchases button
                Button(action: handleRestore) {
                    HStack(spacing: 6) {
                        if isRestoring {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.6)))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11, weight: .medium))
                            Text("Restore Purchases")
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                    .foregroundColor(.white.opacity(0.6))
                }
                .disabled(isRestoring)

                Text("•")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))

                // Manage Subscription button
                Button(action: handleManageSubscription) {
                    HStack(spacing: 6) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 11, weight: .medium))
                        Text("Manage Subscription")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func handleRestore() {
        isRestoring = true

        Task {
            do {
                try await subscriptionManager.restorePurchases()
                await MainActor.run {
                    isRestoring = false
                }
            } catch {
                await MainActor.run {
                    onError(error.localizedDescription)
                    isRestoring = false
                }
            }
        }
    }

    private func handleManageSubscription() {
        // Open iOS subscription management in App Store
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            openURL(url)
        }
    }
}

#Preview {
    SubscriptionCardView(
        onPurchaseSuccess: {},
        onError: { _ in },
        onSkip: {}, // Show skip button in preview
        hasScansRemaining: true // Preview with scans remaining
    )
    .padding(24)
    .background(
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.1))
    )
    .padding(20)
    .background(Color.black)
    .environmentObject(SubscriptionManager.shared)
}
