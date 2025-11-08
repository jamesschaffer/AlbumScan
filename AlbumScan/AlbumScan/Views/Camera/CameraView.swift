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
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var scanLimitManager: ScanLimitManager
    @EnvironmentObject var remoteConfigManager: RemoteConfigManager

    @StateObject private var cameraManager = CameraManager()
    @State private var showingHistory = false
    @State private var showSettings = false
    @State private var showWelcomeSheet = false
    @State private var showErrorBanner = false
    @State private var showingMaintenanceAlert = false
    @State private var welcomeSheetHeight: CGFloat = 520  // Dynamic height for welcome sheet
    @State private var settingsSheetHeight: CGFloat = 520  // Dynamic height for settings sheet

    let brandGreen = Color(red: 0, green: 0.87, blue: 0.32)

    private var settingsButton: some View {
        Button(action: {
            showSettings = true
        }) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 64, height: 64)

                Circle()
                    .strokeBorder(brandGreen, lineWidth: 4)
                    .frame(width: 64, height: 64)

                // Show scan count or lightning bolt icon inside circle
                // Show bolt if: user has subscription OR no scans remaining
                if subscriptionManager.subscriptionTier != .none || scanLimitManager.remainingFreeScans == 0 {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    // Show scan count only for non-subscribers with scans remaining
                    Text("\(scanLimitManager.remainingFreeScans)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(PressedButtonStyle())
    }

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
                        // Left side - scan counter/upgrade button (hide for Ultra subscribers)
                        if subscriptionManager.subscriptionTier != .ultra {
                            settingsButton
                        } else {
                            // Placeholder to maintain spacing when Ultra
                            Color.clear
                                .frame(width: 64, height: 64)
                        }

                        Spacer()

                        // Center - Scan button
                        Button(action: handleScanAction) {
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
                        .disabled(cameraManager.isCaptureInitiated)
                        .opacity(cameraManager.isCaptureInitiated ? 0.4 : 1.0)

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

                    #if DEBUG
                    // Debug Controls - positioned below scan button
                    VStack(spacing: 8) {
                        Text("🔧 Debug")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.orange)

                        HStack(spacing: 8) {
                            Button("Base") {
                                subscriptionManager.debugSetTier(.base)
                                subscriptionManager.debugPrintState()
                            }
                            .font(.system(size: 11))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(6)

                            Button("Ultra") {
                                subscriptionManager.debugSetTier(.ultra)
                                subscriptionManager.debugPrintState()
                            }
                            .font(.system(size: 11))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(6)

                            Button("Clear") {
                                subscriptionManager.debugClearTier()
                                scanLimitManager.resetForTesting()
                                appState.searchEnabled = false
                                subscriptionManager.debugPrintState()
                            }
                            .font(.system(size: 11))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        }
                    }
                    .padding(12)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(12)
                    .padding(.bottom, 20)
                    #endif
                }
            }

            // Loading overlay
            switch cameraManager.scanState {
            case .identifying, .identified, .loadingReview, .complete:
                // Keep loading screen visible during .complete to prevent camera flash
                // during fullScreenCover slide-up animation
                LoadingView(
                    scanState: cameraManager.scanState,
                    phase1Data: cameraManager.phase1Data,
                    albumArtwork: cameraManager.albumArtwork
                )
            case .idle, .identificationFailed, .reviewFailed:
                EmptyView()
            }

            // Error banner for identification failures
            VStack(spacing: 0) {
                if showErrorBanner {
                    VStack(spacing: 0) {
                        // Safe area spacer
                        Color.clear
                            .frame(height: geometry.safeAreaInsets.top)

                        // Error message
                        Text("Unable to identify this cover art")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red)
                    }
                    .transition(.move(edge: .top))
                }

                Spacer()
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showErrorBanner)
        }
        .fullScreenCover(isPresented: $showingHistory) {
            ScanHistoryView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(sheetHeight: $settingsSheetHeight)
                .environmentObject(appState)
                .environmentObject(subscriptionManager)
                .environmentObject(scanLimitManager)
                .presentationDetents([.height(settingsSheetHeight)])
        }
        .sheet(isPresented: $showWelcomeSheet) {
            WelcomePurchaseSheet(
                onDismiss: {
                    showWelcomeSheet = false
                    appState.requestCameraPermission()
                },
                sheetHeight: $welcomeSheetHeight
            )
            .environmentObject(appState)
            .environmentObject(subscriptionManager)
            .environmentObject(scanLimitManager)
            .presentationDetents([.height(welcomeSheetHeight)])
        }
        .fullScreenCover(item: $cameraManager.scannedAlbum, onDismiss: {
            // Reset state when album details is manually dismissed
            cameraManager.scanState = .idle
            cameraManager.isProcessing = false
            cameraManager.isCaptureInitiated = false
        }) { album in
            AlbumDetailsView(album: album, cameraManager: cameraManager)
        }
        .onAppear {
            cameraManager.startSession()

            // Show welcome sheet on first launch
            if appState.isFirstLaunch {
                // Show sheet with a small delay to ensure camera view is visible
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showWelcomeSheet = true
                }
            }

            // Setup guide coordinates (use a small delay to ensure preview layer is sized)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let screenSize = UIScreen.main.bounds.size
                // Preview layer fills the entire screen with .resizeAspectFill
                cameraManager.setupFramingGuide(
                    screenSize: screenSize,
                    previewBounds: screenSize
                )
            }
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .onChange(of: cameraManager.scannedAlbum) { _, newAlbum in
            if newAlbum != nil {
                appState.albumScanned()
            }
        }
        .onChange(of: cameraManager.scanState) { _, newState in
            if newState == .identificationFailed {
                // Show error banner
                showErrorBanner = true

                // Auto-dismiss after 3 seconds and reset state
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    showErrorBanner = false
                    cameraManager.scanState = .idle
                    cameraManager.isCaptureInitiated = false
                }
            }
        }
        .alert("Maintenance", isPresented: $showingMaintenanceAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(remoteConfigManager.maintenanceMessage)
        }
    }

    // MARK: - Actions

    private func handleScanAction() {
        // Check 1: Remote config kill switch
        guard remoteConfigManager.scanningEnabled else {
            #if DEBUG
            print("🔴 [Scan] Blocked by remote config kill switch")
            #endif
            showingMaintenanceAlert = true
            return
        }

        // Check 2: Scan limit (if not subscribed)
        guard scanLimitManager.canScan(isSubscribed: subscriptionManager.isSubscribed) else {
            #if DEBUG
            print("🔴 [Scan] Blocked by scan limit - showing settings/upgrade")
            #endif
            showSettings = true
            return
        }

        // All checks passed - proceed with scan
        #if DEBUG
        print("✅ [Scan] All checks passed - starting scan")
        #endif

        // Pass managers to CameraManager for post-scan increment
        cameraManager.subscriptionManager = subscriptionManager
        cameraManager.scanLimitManager = scanLimitManager
        cameraManager.appState = appState

        cameraManager.capturePhoto()
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
