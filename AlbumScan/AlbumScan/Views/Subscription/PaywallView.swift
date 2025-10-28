import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var scanLimitManager: ScanLimitManager

    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    // Brand colors
    private let brandGreen = Color(red: 0, green: 0.87, blue: 0.32)

    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // Header
                VStack(spacing: 12) {
                    Image(systemName: "infinity.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(brandGreen)

                    Text("Unlock Unlimited Scans")
                        .font(.system(size: 32, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Discover unlimited albums for less than\nthe price of one vinyl record")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Features
                VStack(alignment: .leading, spacing: 20) {
                    FeatureRow(icon: "camera.fill", text: "Unlimited album scans", color: brandGreen)
                    FeatureRow(icon: "doc.text.fill", text: "Full music reviews & context", color: brandGreen)
                    FeatureRow(icon: "sparkles", text: "No ads, ever", color: brandGreen)
                    FeatureRow(icon: "lock.shield.fill", text: "Complete privacy", color: brandGreen)
                }
                .padding(.horizontal, 40)

                Spacer()

                // Pricing
                if let product = subscriptionManager.availableProduct {
                    VStack(spacing: 8) {
                        Text(product.displayPrice)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(brandGreen)

                        Text("per year")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.6))
                    }
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: brandGreen))
                }

                // Subscribe Button
                Button(action: handlePurchase) {
                    HStack {
                        if isPurchasing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        } else {
                            Text("Subscribe Now")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(brandGreen)
                    .cornerRadius(16)
                }
                .disabled(isPurchasing || subscriptionManager.availableProduct == nil)
                .padding(.horizontal, 40)

                // Restore Purchases Button
                Button(action: handleRestore) {
                    Text("Restore Purchases")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(brandGreen)
                }
                .disabled(isPurchasing)

                // Remaining scans indicator
                Text(scanLimitManager.getStatusText())
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 10)

                // Close button (if presented as sheet)
                Button(action: { dismiss() }) {
                    Text("Maybe Later")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.bottom, 20)
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
                // Success! Dismiss paywall
                await MainActor.run {
                    dismiss()
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

    private func handleRestore() {
        isPurchasing = true

        Task {
            do {
                try await subscriptionManager.restorePurchases()
                // Success! Dismiss paywall
                await MainActor.run {
                    dismiss()
                }
            } catch SubscriptionError.noActiveSubscription {
                await MainActor.run {
                    errorMessage = "No active subscription found. If you've already subscribed, please try again later."
                    showError = true
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

// MARK: - Feature Row Component

struct FeatureRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 32)

            Text(text)
                .font(.system(size: 18))
                .foregroundColor(.white)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
        .environmentObject(SubscriptionManager.shared)
        .environmentObject(ScanLimitManager.shared)
}
