import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    private let brandGreen = Color(red: 0, green: 0.87, blue: 0.32)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Ultra Benefits Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("AlbumScan Ultra")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    // Only show price before purchase
                    if !subscriptionManager.isSubscribed {
                        if let product = subscriptionManager.availableProduct {
                            Text("\(product.displayPrice)/year")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(brandGreen)
                        } else {
                            Text("Loading...")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(brandGreen.opacity(0.6))
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        BenefitRow(text: "Unlimited album scans, forever", color: brandGreen)
                        BenefitRow(text: "Improve scans on obscure albums", color: brandGreen)
                        BenefitRow(text: "Access reviews from credible industry experts", color: brandGreen)
                        BenefitRow(text: "Build expertise with verified facts, not AI guesses", color: brandGreen)
                    }
                    .padding(.top, 8)

                    // Conditional UI based on subscription state
                    if subscriptionManager.isSubscribed {
                        // After Purchase State
                        VStack(alignment: .leading, spacing: 12) {
                            Text("You are now leveraging AlbumScan Ultra")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(brandGreen)
                                .padding(.top, 16)

                            Text("To manage your subscription or cancel renewal, visit the App Store.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.top, 8)

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
                    } else {
                        // Before Purchase State
                        Button(action: handlePurchase) {
                            HStack {
                                if isPurchasing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Upgrade")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(brandGreen)
                            .cornerRadius(12)
                        }
                        .disabled(isPurchasing || subscriptionManager.availableProduct == nil)
                        .padding(.top, 16)
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Actions

    private func handlePurchase() {
        isPurchasing = true

        Task {
            do {
                try await subscriptionManager.purchase()
                // Success! Update AppState to enable search
                await MainActor.run {
                    appState.searchEnabled = true
                    isPurchasing = false
                }
            } catch SubscriptionError.userCancelled {
                // User cancelled - no error message needed
                await MainActor.run {
                    isPurchasing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isPurchasing = false
                }
            }
        }
    }
}

struct BenefitRow: View {
    let text: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 20, alignment: .center)

            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
        .environmentObject(SubscriptionManager.shared)
}
