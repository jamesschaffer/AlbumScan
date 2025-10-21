import SwiftUI
import AVFoundation

struct CameraView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var cameraManager = CameraManager()
    @State private var showingHistory = false

    let brandGreen = Color(red: 0, green: 0.87, blue: 0.32)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera feed
                CameraPreview(session: cameraManager.session)
                    .ignoresSafeArea()

                // Black overlay with cutout for framing guide
                FramingGuideOverlay(geometry: geometry, brandGreen: brandGreen)

                // Logo at top
                VStack(spacing: 0) {
                    Image("album-scan-logo-simple-white")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 185)
                        .padding(.top, 20)

                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .center)

                // Camera controls at bottom
                VStack {
                    Spacer()

                    HStack(spacing: 20) {
                        // Scan button
                        Button(action: {
                            cameraManager.capturePhoto()
                        }) {
                            Text("SCAN")
                                .font(.system(size: 28, weight: .heavy))
                                .foregroundColor(.white)
                                .frame(width: 280, height: 60)
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(brandGreen, lineWidth: 4)
                                )
                        }

                        // History button (hamburger menu)
                        if appState.hasScannedAlbums {
                            Button(action: {
                                showingHistory = true
                            }) {
                                VStack(spacing: 4) {
                                    Rectangle()
                                        .fill(Color.white)
                                        .frame(width: 20, height: 2)
                                    Rectangle()
                                        .fill(Color.white)
                                        .frame(width: 20, height: 2)
                                    Rectangle()
                                        .fill(Color.white)
                                        .frame(width: 20, height: 2)
                                }
                                .frame(width: 60, height: 60)
                                .background(Color.clear)
                                .overlay(
                                    Circle()
                                        .stroke(brandGreen, lineWidth: 4)
                                )
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }

            // Loading overlay
            if cameraManager.isProcessing {
                SearchPreLoaderView()
            }
        }
        .sheet(isPresented: $showingHistory) {
            ScanHistoryView()
        }
        .sheet(item: $cameraManager.scannedAlbum) { album in
            AlbumDetailsView(album: album)
        }
        .onAppear {
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
}

// MARK: - Framing Guide Overlay

struct FramingGuideOverlay: View {
    let geometry: GeometryProxy
    let brandGreen: Color

    var guideSize: CGFloat {
        // Calculate the largest square that fits with 20px margins on left/right
        let availableWidth = geometry.size.width - 40
        return availableWidth
    }

    var body: some View {
        ZStack {
            // Black overlay covering entire screen
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            // Clear square cutout for the guide - centered vertically
            Rectangle()
                .frame(width: guideSize, height: guideSize)
                .blendMode(.destinationOut)

            // Green border for the guide
            Rectangle()
                .stroke(brandGreen, lineWidth: 4)
                .frame(width: guideSize, height: guideSize)
        }
        .compositingGroup()
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
            .environmentObject(AppState())
    }
}
