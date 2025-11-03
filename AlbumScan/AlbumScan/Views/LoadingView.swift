import SwiftUI

/// Unified loading view for two-tier album identification flow
/// Handles all four states:
/// 1. Identifying (ID Call 1 - first 3.5s): "Extracting text and examining album art..."
/// 2. Identifying (ID Call 1 - remaining time): "Flipping through every record bin..."
/// 3. Identified: Artwork + "We found {album} by {artist}" (2 seconds)
/// 4. Loading Review: Artwork + "Writing a review..."
///
/// UX improvement: States 1-2 both occur during ID Call 1 to break up the 7-15s wait
struct LoadingView: View {
    let scanState: ScanState
    let phase1Data: Phase1Response?
    let albumArtwork: UIImage?

    @State private var showingReviewMessage = false
    @State private var showingRecordBinMessage = false
    @State private var showAlbumContent = false  // Controls when to actually show album content (delayed for animation)
    @State private var ellipsisDots = 1

    // Animation states
    @State private var textOpacity: Double = 0
    @State private var offsetX: CGFloat = 0
    @State private var albumOpacity: Double = 0

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

    // Computed property: should we show the album found section (based on scan state)?
    private var shouldShowAlbumSection: Bool {
        return scanState == .identified || scanState == .loadingReview || scanState == .complete
    }

    // Computed property: are we actually ready to display album content (after animation)?
    private var displayAlbumSection: Bool {
        return shouldShowAlbumSection && showAlbumContent
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
                    let hasAlbum = displayAlbumSection
                    let topSpacerHeight = (geometry.size.height * textTopPosition) - (hasAlbum ? (albumSize + albumTextSpacing) : 0)

                    Spacer()
                        .frame(height: topSpacerHeight)

                    // Album cover (only shown in identified/review states)
                    if displayAlbumSection {
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
                        .opacity(albumOpacity)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 30)

                        // Fixed spacing between album and text
                        Spacer()
                            .frame(height: albumTextSpacing)
                    }

                    // Text content - top edge is ALWAYS at 50% screen height
                    contentText(geometry: geometry)
                        .padding(.horizontal, 30)
                        .opacity(textOpacity)
                        .offset(x: offsetX)

                    // Bottom spacer fills remaining space
                    Spacer()
                }
            }
        }
        .onChange(of: shouldShowAlbumSection) { oldValue, newValue in
            // When we transition to showing album section (ID Call 1 complete, artwork ready)
            if !oldValue && newValue {
                #if DEBUG
                print("🎬 [LoadingView] ID Call 1 completed, transitioning to album section")
                #endif

                // Slide out current message (either "Extracting text..." or "Flipping through record bin...")
                withAnimation(.easeIn(duration: 0.3)) {
                    offsetX = -UIScreen.main.bounds.width
                }

                // After slide completes, switch content and show album section
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // NOW switch to album content (after old content is off-screen)
                    self.showAlbumContent = true

                    // Reset position and opacity
                    self.offsetX = 0
                    self.textOpacity = 0
                    self.albumOpacity = 0

                    // Fade in album and text together
                    withAnimation(.easeIn(duration: 0.4)) {
                        self.albumOpacity = 1.0
                        self.textOpacity = 1.0
                    }

                    // Start the 2-second timer for next transition
                    self.startReviewTransitionTimer()
                }
            }
        }
        .onAppear {
            // Start ellipsis animation
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                ellipsisDots = (ellipsisDots % 3) + 1
            }

            // Initial fade in: wait 0.5s, then fade from opacity 0 to 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeIn(duration: 0.4)) {
                    textOpacity = 1.0
                }
            }

            // If already in album section when view appears (edge case), fade in album and start timer
            if shouldShowAlbumSection {
                #if DEBUG
                print("🎬 [LoadingView] View appeared with album section already visible, fading in album and starting timer")
                #endif

                // Skip intermediate states in this edge case
                showingRecordBinMessage = true
                showAlbumContent = true

                withAnimation(.easeIn(duration: 0.4)) {
                    albumOpacity = 1.0
                }

                startReviewTransitionTimer()
            } else {
                // UX improvement: Transition from "Extracting text..." to "Flipping through record bin..."
                // after 3.5 seconds to break up the long ID Call 1 wait
                #if DEBUG
                print("🎬 [LoadingView] Starting 3.5s timer to transition to record bin message")
                #endif

                DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                    // Only transition if we're still in identifying state (not already moved to album section)
                    guard !self.shouldShowAlbumSection else {
                        #if DEBUG
                        print("🎬 [LoadingView] Already moved to album section, skipping record bin transition")
                        #endif
                        return
                    }

                    #if DEBUG
                    print("🎬 [LoadingView] Transitioning from extracting text to record bin message")
                    #endif

                    // Slide out "Extracting text..." message
                    withAnimation(.easeIn(duration: 0.3)) {
                        self.offsetX = -UIScreen.main.bounds.width
                    }

                    // After slide completes, show "Flipping through record bin..." message
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        // Update to record bin message
                        self.showingRecordBinMessage = true

                        // Reset position and opacity
                        self.offsetX = 0
                        self.textOpacity = 0

                        // Fade in record bin message
                        withAnimation(.easeIn(duration: 0.4)) {
                            self.textOpacity = 1.0
                        }
                    }
                }
            }
        }
    }

    // MARK: - Content Views

    @ViewBuilder
    private func contentText(geometry: GeometryProxy) -> some View {
        if !displayAlbumSection && !showingRecordBinMessage {
            // State 1: Initial identifying (ID Call 1)
            (Text("Extracting text and examining album art")
                .foregroundColor(messageColor) +
             Text(String(repeating: ".", count: ellipsisDots))
                .foregroundColor(brandGreen))
                .font(.system(size: messageFontSize))
                .lineSpacing(messageLineHeight)
                .frame(maxWidth: geometry.size.width * textWidthPercentage, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if showingRecordBinMessage && !displayAlbumSection {
            // State 2: ID Call 1 continuing (after 3.5s transition)
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
            // State 3/4: Album found or writing review
            Group {
                if !showingReviewMessage {
                    foundMessageView(geometry: geometry)
                } else {
                    reviewMessageView(geometry: geometry)
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
        // After 2 seconds, slide out "We found..." and fade in "Writing a review..."
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Slide out left
            withAnimation(.easeIn(duration: 0.3)) {
                self.offsetX = -UIScreen.main.bounds.width
            }

            // After slide completes, fade in new text
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // Update to review message
                self.showingReviewMessage = true

                // Reset position and opacity
                self.offsetX = 0
                self.textOpacity = 0

                // Fade in new text (no exit animation for this one)
                withAnimation(.easeIn(duration: 0.4)) {
                    self.textOpacity = 1.0
                }
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
