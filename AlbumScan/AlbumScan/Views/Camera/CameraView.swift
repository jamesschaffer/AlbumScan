import SwiftUI
import AVFoundation

struct CameraView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var cameraManager = CameraManager()
    @State private var showingHistory = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera feed
                CameraPreview(session: cameraManager.session)
                    .ignoresSafeArea()

                // Black overlay with cutout for framing guide
                FramingGuideOverlay(geometry: geometry)

                // Camera controls
                VStack {
                    Spacer()

                    // Scan button
                    Button(action: {
                        cameraManager.capturePhoto()
                    }) {
                        Text("SCAN")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(Color.blue)
                            .cornerRadius(25)
                    }
                    .padding(.bottom, 40)
                }
            }

            // History button (top-right)
            if appState.hasScannedAlbums {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            showingHistory = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "clock")
                                    .font(.body)
                                Text("History")
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(20)
                        }
                        .padding()
                    }
                    Spacer()
                }
            }

            // Loading overlay
            if cameraManager.isProcessing {
                SearchPreLoaderView(currentStage: $cameraManager.loadingStage)
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

            // White border for the guide
            Rectangle()
                .stroke(Color.white, lineWidth: 3)
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
