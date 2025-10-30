import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

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
                    if !appState.hasActiveSubscription {
                        Text("$11.99/year")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(red: 0, green: 0.87, blue: 0.32))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        BenefitRow(text: "Improve scans on obscure albums that shaped your favorite artists")
                        BenefitRow(text: "Access reviews from credible industry experts like Pitchfork")
                        BenefitRow(text: "Stay ahead with live updates on albums released after 2024")
                        BenefitRow(text: "Build expertise with verified facts, not AI guesses")
                    }
                    .padding(.top, 8)

                    // Conditional UI based on subscription state
                    if appState.hasActiveSubscription {
                        // After Purchase State
                        VStack(alignment: .leading, spacing: 12) {
                            Text("You are now leveraging AlbumScan Ultra")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(red: 0, green: 0.87, blue: 0.32))
                                .padding(.top, 16)

                            Text("To manage your subscription or cancel renewal, visit the App Store.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.top, 8)

                            #if DEBUG
                            Button(action: {
                                appState.hasActiveSubscription = false
                            }) {
                                Text("Reset for Testing")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.red)
                            }
                            .padding(.top, 12)
                            #endif
                        }
                    } else {
                        // Before Purchase State
                        Button(action: {
                            // Simulate purchase (for testing - will be replaced with StoreKit 2)
                            appState.hasActiveSubscription = true
                        }) {
                            Text("Upgrade")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(red: 0, green: 0.87, blue: 0.32))
                                .cornerRadius(12)
                        }
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
    }
}

struct BenefitRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(Color(red: 0, green: 0.87, blue: 0.32))
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
}
