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

                    Text("$11.99/year")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(red: 0, green: 0.87, blue: 0.32))

                    VStack(alignment: .leading, spacing: 12) {
                        BenefitRow(text: "Leverages web search for obscure albums")
                        BenefitRow(text: "Enhanced accuracy for modern releases (2020+)")
                        BenefitRow(text: "Cited sources in review from major music outlets")
                        BenefitRow(text: "Reduces potential hallucinations")
                        BenefitRow(text: "Support continued development efforts")
                    }
                    .padding(.top, 8)

                    // Toggle Switch (Placeholder - no purchase flow yet)
                    HStack {
                        Text("Enable Advanced Search")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)

                        Spacer()

                        Toggle("", isOn: $appState.searchEnabled)
                            .labelsHidden()
                            .tint(Color(red: 0, green: 0.87, blue: 0.32))
                    }
                    .padding(.top, 16)
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

            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
