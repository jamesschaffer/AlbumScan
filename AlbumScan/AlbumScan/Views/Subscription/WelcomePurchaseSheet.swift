import SwiftUI
import StoreKit

struct WelcomePurchaseSheet: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var scanLimitManager: ScanLimitManager

    let onDismiss: () -> Void

    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Comprehensive subscription component
                SubscriptionCardView(
                    onPurchaseSuccess: {
                        // Success! Dismiss sheet and request camera permission
                        onDismiss()
                    },
                    onError: { error in
                        errorMessage = error
                        showError = true
                    },
                    onSkip: {
                        // Use free scans - dismiss sheet
                        onDismiss()
                    },
                    hasScansRemaining: scanLimitManager.remainingFreeScans > 0
                )
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                )
                .padding(.horizontal, 20)
                .padding(.top, 20)
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
    WelcomePurchaseSheet(onDismiss: {})
        .environmentObject(AppState())
        .environmentObject(SubscriptionManager.shared)
        .environmentObject(ScanLimitManager.shared)
}
