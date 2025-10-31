import Foundation
import Combine
import SwiftUI
import AVFoundation
import CoreData

class AppState: ObservableObject {
    @Published var isFirstLaunch: Bool = true
    @Published var cameraPermissionDenied: Bool = false
    @Published var hasScannedAlbums: Bool = false

    // MARK: - AlbumScan Ultra Subscription State

    @Published var hasActiveSubscription: Bool {
        didSet {
            UserDefaults.standard.set(hasActiveSubscription, forKey: "hasActiveSubscription")
            // When subscription becomes active, automatically enable search
            if hasActiveSubscription {
                searchEnabled = true
            }
            #if DEBUG
            print("💎 [AlbumScan Ultra] Subscription state changed to: \(hasActiveSubscription)")
            #endif
        }
    }

    @Published var searchEnabled: Bool {
        didSet {
            UserDefaults.standard.set(searchEnabled, forKey: "searchEnabled")
            #if DEBUG
            print("🔍 [AlbumScan Ultra] Search enabled changed to: \(searchEnabled)")
            #endif
        }
    }

    init() {
        // Check if first launch
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        self.isFirstLaunch = !hasLaunchedBefore

        // Load subscription state from UserDefaults
        self.hasActiveSubscription = UserDefaults.standard.bool(forKey: "hasActiveSubscription")

        // Load search toggle state from UserDefaults
        self.searchEnabled = UserDefaults.standard.bool(forKey: "searchEnabled")

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
