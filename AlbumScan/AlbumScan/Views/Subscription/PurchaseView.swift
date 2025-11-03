import SwiftUI
import StoreKit

struct PurchaseView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var scanLimitManager: ScanLimitManager
    @Environment(\.dismiss) var dismiss

    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with dismiss button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Spacer()

                // Comprehensive subscription component
                SubscriptionCardView(
                    onPurchaseSuccess: {
                        // Success! Dismiss view
                        dismiss()
                    },
                    onError: { error in
                        errorMessage = error
                        showError = true
                    },
                    onSkip: {
                        // Use free scans - dismiss view
                        dismiss()
                    },
                    hasScansRemaining: scanLimitManager.remainingFreeScans > 0
                )
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                )
                .padding(.horizontal, 20)
                .environmentObject(subscriptionManager)

                Spacer()
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
}

#Preview {
    PurchaseView()
        .environmentObject(SubscriptionManager.shared)
        .environmentObject(ScanLimitManager.shared)
}
