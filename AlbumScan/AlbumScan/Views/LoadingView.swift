import SwiftUI

/// Unified loading view for two-tier album identification flow
/// Handles all three states:
/// 1. Identifying: "Flipping through every record bin..."
/// 2. Identified: Artwork + "We found {album} by {artist}" (2 seconds)
/// 3. Loading Review: Artwork + "Writing a review..."
struct LoadingView: View {
    let scanState: ScanState
    let phase1Data: Phase1Response?
    let albumArtwork: UIImage?

    @State private var showingReviewMessage = false
    @State private var ellipsisDots = 1

    // MARK: - Layout Constants

    private let messageFontSize: CGFloat = 24
    private let messageLineHeight: CGFloat = 6
    private let messageColor: Color = .white
    private let albumSize: CGFloat = 150  // Album cover size
    private let albumTextSpacing: CGFloat = 20  // Fixed spacing between album and text
    private let textTopPosition: CGFloat = 0.5  // Text always starts at 50% screen height
    private let textWidthPercentage: CGFloat = 0.75
    private let transitionDuration: Double = 0.4

    // Brand Colors
    let brandGreen = Color(red: 0, green: 0.87, blue: 0.32)
    let placeholderGray = Color(white: 0.2)

    // Computed property: should we show the album found section?
    private var shouldShowAlbumSection: Bool {
        return scanState == .identified || scanState == .loadingReview || scanState == .complete
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black background
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Logo at top
                    HStack {
                        Spacer()
                        Image("album-scan-logo-simple-white")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 185)
                        Spacer()
                    }
                    .padding(.top, 20)

                    // Calculate top spacer to position text at exactly 50% screen height
                    // When album present: 50% - (albumSize + spacing)
                    // When album absent: 50%
                    let hasAlbum = shouldShowAlbumSection
                    let topSpacerHeight = (geometry.size.height * textTopPosition) - (hasAlbum ? (albumSize + albumTextSpacing) : 0)

                    Spacer()
                        .frame(height: topSpacerHeight)

                    // Album cover (only shown in identified/review states)
                    if shouldShowAlbumSection {
                        Group {
                            if let artwork = albumArtwork {
                                Image(uiImage: artwork)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: albumSize, height: albumSize)
                                    .clipped()
                                    .cornerRadius(4)
                            } else {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(placeholderGray)
                                    .frame(width: albumSize, height: albumSize)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 30)

                        // Fixed spacing between album and text
                        Spacer()
                            .frame(height: albumTextSpacing)
                    }

                    // Text content - top edge is ALWAYS at 50% screen height
                    contentText(geometry: geometry)
                        .padding(.horizontal, 30)

                    // Bottom spacer fills remaining space
                    Spacer()
                }
            }
        }
        .onChange(of: shouldShowAlbumSection) { oldValue, newValue in
            // When we transition to showing album section, start 2-second timer
            if !oldValue && newValue {
                print("🎬 [LoadingView] Transitioning to album section, starting 2-second timer")
                startReviewTransitionTimer()
            }
        }
        .onAppear {
            // Start ellipsis animation
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                ellipsisDots = (ellipsisDots % 3) + 1
            }

            // If already in album section when view appears (edge case), start timer
            if shouldShowAlbumSection {
                print("🎬 [LoadingView] View appeared with album section already visible, starting timer")
                startReviewTransitionTimer()
            }
        }
    }

    // MARK: - Content Views

    @ViewBuilder
    private func contentText(geometry: GeometryProxy) -> some View {
        if !shouldShowAlbumSection {
            // State 1: Identifying
            (Text("Flipping through every record bin in existence")
                .foregroundColor(messageColor) +
             Text(String(repeating: ".", count: ellipsisDots))
                .foregroundColor(brandGreen))
                .font(.system(size: messageFontSize))
                .lineSpacing(messageLineHeight)
                .frame(maxWidth: geometry.size.width * textWidthPercentage, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            // State 2/3: Album found or writing review
            Group {
                if !showingReviewMessage {
                    foundMessageView(geometry: geometry)
                        .transition(.opacity)
                } else {
                    reviewMessageView(geometry: geometry)
                        .transition(.opacity)
                }
            }
        }
    }

    // MARK: - Text Messages

    private func foundMessageView(geometry: GeometryProxy) -> some View {
        (Text("We found ")
            .foregroundColor(messageColor) +
         Text(phase1Data?.albumTitle ?? "Unknown Album")
            .foregroundColor(brandGreen) +
         Text(" by ")
            .foregroundColor(messageColor) +
         Text(phase1Data?.artistName ?? "Unknown Artist")
            .foregroundColor(brandGreen))
            .font(.system(size: messageFontSize))
            .lineSpacing(messageLineHeight)
            .frame(maxWidth: geometry.size.width * textWidthPercentage, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func reviewMessageView(geometry: GeometryProxy) -> some View {
        (Text("Writing a review that's somehow both pretentious and correct")
            .foregroundColor(messageColor) +
         Text(String(repeating: ".", count: ellipsisDots))
            .foregroundColor(brandGreen))
            .font(.system(size: messageFontSize))
            .lineSpacing(messageLineHeight)
            .frame(maxWidth: geometry.size.width * textWidthPercentage, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Timer

    private func startReviewTransitionTimer() {
        // After 2 seconds, fade from "We found..." to "Writing a review..."
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: transitionDuration)) {
                showingReviewMessage = true
            }
        }
    }
}

#Preview {
    LoadingView(
        scanState: .identified,
        phase1Data: Phase1Response(
            success: true,
            artistName: "Radiohead",
            albumTitle: "OK Computer",
            releaseYear: "1997",
            genres: ["Alternative Rock"],
            recordLabel: "Parlophone",
            errorMessage: nil
        ),
        albumArtwork: nil
    )
}
