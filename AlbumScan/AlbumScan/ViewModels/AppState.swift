import Foundation
import Combine
import SwiftUI
import AVFoundation
import CoreData

class AppState: ObservableObject {
    // MARK: - Dev Mode Settings
    #if DEBUG
    // Set to true to always show welcome screen on launch (for testing)
    private let FORCE_WELCOME_SCREEN = true
    #endif

    @Published var isFirstLaunch: Bool = true
    @Published var cameraPermissionDenied: Bool = false
    @Published var hasScannedAlbums: Bool = false

    // MARK: - AI Provider Selection (Debug Only)
    #if DEBUG
    @Published var selectedProvider: LLMProvider {
        didSet {
            UserDefaults.standard.set(selectedProvider.rawValue, forKey: Config.UserDefaultsKeys.selectedLLMProvider)
            print("🤖 [Provider] Changed to: \(selectedProvider.displayName)")
        }
    }
    #endif

    init() {
        #if DEBUG
        // Dev Mode: Force welcome screen if enabled
        if FORCE_WELCOME_SCREEN {
            self.isFirstLaunch = true
            print("🔧 [DEV MODE] Forcing welcome screen to show")
        } else {
            let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
            self.isFirstLaunch = !hasLaunchedBefore
        }
        #else
        // Check if first launch (production)
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        self.isFirstLaunch = !hasLaunchedBefore
        #endif

        #if DEBUG
        // Load saved provider preference (default to OpenAI for existing users)
        if let savedProvider = UserDefaults.standard.string(forKey: Config.UserDefaultsKeys.selectedLLMProvider),
           let provider = LLMProvider(rawValue: savedProvider) {
            self.selectedProvider = provider
        } else {
            self.selectedProvider = .openAI  // Default for new users
        }
        print("🤖 [Provider] Initialized with: \(selectedProvider.displayName)")
        #endif

        // Defer album check to avoid initialization issues
        checkForScannedAlbums()
    }

    private func checkForScannedAlbums() {
        // Check if user has scanned any albums
        self.hasScannedAlbums = !PersistenceController.shared.fetchAllAlbums().isEmpty
    }

    func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.isFirstLaunch = false
                    self?.cameraPermissionDenied = false
                    UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
                } else {
                    self?.cameraPermissionDenied = true
                }
            }
        }
    }

    func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        cameraPermissionDenied = (status == .denied || status == .restricted)
    }

    func albumScanned() {
        hasScannedAlbums = true
    }
}
