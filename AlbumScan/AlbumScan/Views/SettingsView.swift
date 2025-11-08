import SwiftUI
import StoreKit

// PreferenceKey to measure content height (shared with WelcomePurchaseSheet)
struct SettingsViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var scanLimitManager: ScanLimitManager
    @Environment(\.dismiss) var dismiss

    @Binding var sheetHeight: CGFloat  // Expose measured height to parent

    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Single comprehensive subscription component
                SubscriptionCardView(
                    onPurchaseSuccess: {
                        // Purchase successful - tier is automatically detected and saved
                    },
                    onError: { error in
                        errorMessage = error
                        showError = true
                    },
                    onSkip: subscriptionManager.subscriptionTier == .none ? {
                        // User has no subscription - allow them to use free scans
                        dismiss()
                    } : nil, // Base/Ultra users don't need skip button
                    hasScansRemaining: scanLimitManager.remainingFreeScans > 0
                )
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                )
                .padding(20)  // Consistent 20pt margin on all sides
                .environmentObject(subscriptionManager)
            }
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onChange(of: geometry.size) { oldSize, newSize in
                            #if DEBUG
                            print("📏 [SettingsView] Size changed: \(oldSize) → \(newSize)")
                            #endif

                            // Update whenever size changes (handles loading → loaded transitions)
                            let cappedHeight = min(newSize.height, UIScreen.main.bounds.height * 0.9)

                            #if DEBUG
                            print("📏 [SettingsView] Setting sheet height to: \(cappedHeight)")
                            #endif

                            sheetHeight = cappedHeight
                        }
                        .onAppear {
                            #if DEBUG
                            print("📏 [SettingsView] Initial size on appear: \(geometry.size)")
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
    struct PreviewWrapper: View {
        @State private var height: CGFloat = 520

        var body: some View {
            SettingsView(sheetHeight: $height)
                .environmentObject(AppState())
                .environmentObject(SubscriptionManager.shared)
                .environmentObject(ScanLimitManager.shared)
        }
    }

    return PreviewWrapper()
}
