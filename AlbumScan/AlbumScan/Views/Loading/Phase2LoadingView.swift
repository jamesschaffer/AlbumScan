import SwiftUI

/// Screen 2C: Phase 2 Review Loading
/// Shows album artwork while review generates in background (3-6 seconds)
struct Phase2LoadingView: View {
    let albumTitle: String
    let artistName: String
    let albumArtwork: UIImage?

    @State private var ellipsisDots = 1

    let brandGreen = Color(red: 0, green: 0.87, blue: 0.32)

    var body: some View {
        ZStack {
            // Black background
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Top padding
                    Color.clear.frame(height: 60)

                    // Album artwork (or placeholder)
                    if let artwork = albumArtwork {
                        Image(uiImage: artwork)
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(8)
                            .padding(.horizontal, 20)
                    } else {
                        // Placeholder while artwork loads
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                VStack(spacing: 10) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.5)
                                    Text("Loading artwork...")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            )
                            .cornerRadius(8)
                            .padding(.horizontal, 20)
                    }

                    // Album info
                    VStack(spacing: 8) {
                        Text(albumTitle)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 20)

                        Text(artistName)
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .padding(.horizontal, 20)
                    }

                    // Loading message with animated ellipsis
                    VStack(spacing: 15) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: brandGreen))
                            .scaleEffect(1.2)

                        HStack(spacing: 0) {
                            Text("Writing a review that's somehow both pretentious and correct")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.8))

                            Text(String(repeating: ".", count: ellipsisDots))
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 30, alignment: .leading)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    }
                    .padding(.top, 20)

                    Spacer(minLength: 40)
                }
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
    Phase2LoadingView(
        albumTitle: "OK Computer",
        artistName: "Radiohead",
        albumArtwork: nil
    )
}
