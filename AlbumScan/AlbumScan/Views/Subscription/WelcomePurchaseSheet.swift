import SwiftUI
import StoreKit

// PreferenceKey to measure content height
struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct WelcomePurchaseSheet: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var scanLimitManager: ScanLimitManager

    let onDismiss: () -> Void
    @Binding var sheetHeight: CGFloat  // Expose measured height to parent

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
                .padding(.bottom, 20)
                .environmentObject(subscriptionManager)
            }
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onChange(of: geometry.size) { oldSize, newSize in
                            #if DEBUG
                            print("📏 [WelcomeSheet] Size changed: \(oldSize) → \(newSize)")
                            #endif

                            // Update whenever size changes (handles loading → loaded transitions)
                            let cappedHeight = min(newSize.height, UIScreen.main.bounds.height * 0.9)

                            #if DEBUG
                            print("📏 [WelcomeSheet] Setting sheet height to: \(cappedHeight)")
                            #endif

                            sheetHeight = cappedHeight
                        }
                        .onAppear {
                            #if DEBUG
                            print("📏 [WelcomeSheet] Initial size on appear: \(geometry.size)")
                            #endif

                            // Set initial height
                            let cappedHeight = min(geometry.size.height, UIScreen.main.bounds.height * 0.9)
                            sheetHeight = cappedHeight
                        }
                }
            )
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var height: CGFloat = 520

        var body: some View {
            WelcomePurchaseSheet(onDismiss: {}, sheetHeight: $height)
                .environmentObject(AppState())
                .environmentObject(SubscriptionManager.shared)
                .environmentObject(ScanLimitManager.shared)
        }
    }

    return PreviewWrapper()
}
