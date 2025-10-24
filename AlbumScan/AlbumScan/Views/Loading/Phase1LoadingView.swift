import SwiftUI

/// Screen 2: Phase 1 Identification Loading
/// Displays while album is being identified (2-4 seconds)
struct Phase1LoadingView: View {
    @State private var ellipsisDots = 1

    let brandGreen = Color(red: 0, green: 0.87, blue: 0.32)

    var body: some View {
        ZStack {
            // Black background
            Color.black.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Header
                Text("ALBUM SCAN")
                    .font(.custom("Bungee", size: 24))
                    .foregroundColor(.white)

                // Loading message with animated ellipsis
                HStack(spacing: 0) {
                    Text("Flipping through every record bin in existence")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.9))

                    Text(String(repeating: ".", count: ellipsisDots))
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(width: 30, alignment: .leading)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

                Spacer()
            }
        }
        .onAppear {
            // Animate ellipsis dots: 1 -> 2 -> 3 -> 1
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                withAnimation {
                    ellipsisDots = (ellipsisDots % 3) + 1
                }
            }
        }
    }
}

#Preview {
    Phase1LoadingView()
}
