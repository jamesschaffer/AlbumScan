import SwiftUI
import StoreKit

/// Comprehensive subscription component that handles all subscription states
/// Automatically shows the appropriate UI based on current subscription tier:
/// - .none: Shows "Choose Your Plan" with Base/Ultra tabs (and optional skip button)
/// - .base: Shows upgrade to Ultra opportunity
/// - .ultra: Shows success state
struct SubscriptionCardView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    @State private var selectedTier: SubscriptionTier = .base
    @State private var isPurchasing = false

    let onPurchaseSuccess: () -> Void
    let onError: (String) -> Void
    let onSkip: (() -> Void)? // Optional callback for "Use free scans" - only shown when provided
    let hasScansRemaining: Bool // Whether user has free scans remaining

    private let brandGreen = Color(red: 0, green: 0.87, blue: 0.32)

    // Check if the selected product is available
    private var isProductAvailable: Bool {
        if subscriptionManager.subscriptionTier == .base {
            // For Base users upgrading to Ultra
            return subscriptionManager.availableUltraProduct != nil
        } else {
            // For new users choosing between Base and Ultra
            switch selectedTier {
            case .base:
                return subscriptionManager.availableBaseProduct != nil
            case .ultra:
                return subscriptionManager.availableUltraProduct != nil
            case .none:
                return false
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Show different UI based on current subscription tier
            switch subscriptionManager.subscriptionTier {
            case .none:
                // No subscription - Show "Choose Your Plan"
                noSubscriptionView

            case .base:
                // Base subscriber - Show upgrade to Ultra
                baseUpgradeView

            case .ultra:
                // Ultra subscriber - Show success state
                ultraSuccessView
            }
        }
    }

    // MARK: - No Subscription View

    private var noSubscriptionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Your Plan")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            // Tab Selector
            HStack(spacing: 0) {
                // Base Tab
                Button(action: { selectedTier = .base }) {
                    VStack(spacing: 8) {
                        Text("Base")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(selectedTier == .base ? .white : .white.opacity(0.6))
                        Text("$4.99/yr")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(selectedTier == .base ? brandGreen : .white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedTier == .base ? Color.white.opacity(0.1) : Color.clear)
                    .overlay(
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(selectedTier == .base ? brandGreen : Color.clear),
                        alignment: .bottom
                    )
                }

                // Ultra Tab
                Button(action: { selectedTier = .ultra }) {
                    VStack(spacing: 8) {
                        Text("Ultra")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(selectedTier == .ultra ? .white : .white.opacity(0.6))
                        Text("$11.99/yr")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(selectedTier == .ultra ? brandGreen : .white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedTier == .ultra ? Color.white.opacity(0.1) : Color.clear)
                    .overlay(
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(selectedTier == .ultra ? brandGreen : Color.clear),
                        alignment: .bottom
                    )
                }
            }
            .padding(.top, 8)

            // Features for selected tier
            VStack(alignment: .leading, spacing: 12) {
                if selectedTier == .base {
                    // Base Features
                    BenefitRow(text: "One-click search, unlike clunky search engines", color: brandGreen)
                    BenefitRow(text: "Concise, reviews that communicate album importance and context", color: brandGreen)
                    BenefitRow(text: "8-tier recommendation system that identifies albums that matter", color: brandGreen)
                } else {
                    // Ultra Features
                    BenefitRow(text: "Improve matches on obscure and new albums", color: brandGreen)
                    BenefitRow(text: "Access reviews from credible industry experts - Pitchform, Rolling Stone, etc.", color: brandGreen)
                    BenefitRow(text: "Benefit from improved scoring and categorozation accuracy", color: brandGreen)
                }
            }
            .padding(.top, 8)

            // Purchase Button
            Button(action: handlePurchase) {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(selectedTier == .base
                             ? "Buy Base - $4.99"
                             : "Buy Ultra - $11.99")
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
                .padding(.top, 20)
            }
        }
    }

    // MARK: - Base Upgrade View

    private var baseUpgradeView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("You have AlbumScan Base")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(brandGreen)

            Text("Upgrade to AlbumScan Ultra")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            Text("$11.99/year")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(brandGreen)

            VStack(alignment: .leading, spacing: 12) {
                BenefitRow(text: "Improve matches on obscure and new albums", color: brandGreen)
                BenefitRow(text: "Access reviews from credible industry experts - Pitchform, Rolling Stone, etc.", color: brandGreen)
                BenefitRow(text: "Benefit from improved scoring and categorozation accuracy", color: brandGreen)
            }
            .padding(.top, 8)

            Button(action: handlePurchase) {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Upgrade to Ultra")
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
        }
    }

    // MARK: - Ultra Success View

    private var ultraSuccessView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AlbumScan Ultra")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text("You are now leveraging AlbumScan Ultra")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(brandGreen)
                .padding(.top, 8)

            Text("To manage your subscription or cancel renewal, visit the App Store.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 4)

            #if DEBUG
            Button(action: {
                // Debug reset - reload subscription status
                Task {
                    await subscriptionManager.checkSubscriptionStatus()
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

    // MARK: - Actions

    private func handlePurchase() {
        isPurchasing = true

        Task {
            do {
                // Determine which tier to purchase
                let tierToPurchase: SubscriptionTier
                if subscriptionManager.subscriptionTier == .base {
                    // Base user upgrading to Ultra
                    tierToPurchase = .ultra
                } else {
                    // New user choosing between Base and Ultra
                    tierToPurchase = selectedTier
                }

                try await subscriptionManager.purchase(tier: tierToPurchase)

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
