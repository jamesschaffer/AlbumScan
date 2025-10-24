import SwiftUI

/// Screen 2B: Album Identified Transition
/// Brief display (0.5s) showing album was successfully identified
struct Phase1TransitionView: View {
    let albumTitle: String
    let artistName: String

    let brandGreen = Color(red: 0, green: 0.87, blue: 0.32)

    var body: some View {
        ZStack {
            // Black background
            Color.black.ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // Header
                Text("ALBUM SCAN")
                    .font(.custom("Bungee", size: 24))
                    .foregroundColor(.white)

                // Album identification
                VStack(spacing: 12) {
                    Text(albumTitle)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Text("by \(artistName)")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                }
                .padding(.horizontal, 40)

                // Small loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: brandGreen))
                    .scaleEffect(1.2)
                    .padding(.top, 10)

                Text("Loading details...")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))

                Spacer()
            }
        }
    }
}

#Preview {
    Phase1TransitionView(
        albumTitle: "OK Computer",
        artistName: "Radiohead"
    )
}
