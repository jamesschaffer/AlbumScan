import SwiftUI
import AVFoundation

// MARK: - Pressed Button Style

struct PressedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

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

                    // Bottom control bar container
                    HStack(alignment: .center, spacing: 0) {
                        // Left side - placeholder for settings button
                        Color.clear
                            .frame(width: 64, height: 64)

                        Spacer()

                        // Center - Scan button
                        Button(action: {
                            cameraManager.capturePhoto()
                        }) {
                            HStack(alignment: .center, spacing: 0) {
                                Text("SCAN")
                                    .font(.custom("Bungee", size: 28))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 40)
                            .padding(.vertical, 26)
                            .frame(width: 201, alignment: .center)
                            .background(.black.opacity(0.6))
                            .cornerRadius(42)
                            .overlay(
                                RoundedRectangle(cornerRadius: 42)
                                    .inset(by: 2)
                                    .stroke(brandGreen, lineWidth: 4)
                            )
                        }
                        .buttonStyle(PressedButtonStyle())

                        Spacer()

                        // Right side - History button
                        if appState.hasScannedAlbums {
                            Button(action: {
                                showingHistory = true
                            }) {
                                HStack(alignment: .center, spacing: 0) {
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
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 20)
                                .frame(width: 64, height: 64, alignment: .center)
                                .background(.black.opacity(0.6))
                                .cornerRadius(999)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 999)
                                        .inset(by: 2)
                                        .stroke(brandGreen, lineWidth: 4)
                                )
                            }
                            .buttonStyle(PressedButtonStyle())
                        } else {
                            // Placeholder to maintain spacing when no history
                            Color.clear
                                .frame(width: 64, height: 64)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 22)
                }
            }

            // Loading overlay
            if cameraManager.isProcessing {
                SearchPreLoaderView(currentStage: $cameraManager.loadingStage)
            }
        }
        .fullScreenCover(isPresented: $showingHistory) {
            ScanHistoryView()
        }
        .fullScreenCover(item: $cameraManager.scannedAlbum) { album in
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
