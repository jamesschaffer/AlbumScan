import SwiftUI
import AVFoundation

struct CameraView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var cameraManager = CameraManager()
    @State private var showingHistory = false

    var body: some View {
        ZStack {
            // Camera feed
            CameraPreview(session: cameraManager.session)
                .ignoresSafeArea()

            // Camera controls overlay
            VStack {
                Spacer()

                // Square framing guide
                Rectangle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 280, height: 280)
                    .padding(.bottom, 60)

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

            // History button (top-right)
            if appState.hasScannedAlbums {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            showingHistory = true
                        }) {
                            Image(systemName: "clock")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding()
                    }
                    Spacer()
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

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
            .environmentObject(AppState())
    }
}
