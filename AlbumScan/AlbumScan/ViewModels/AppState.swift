import Foundation
import Combine
import SwiftUI
import AVFoundation
import CoreData

class AppState: ObservableObject {
    @Published var isFirstLaunch: Bool = true
    @Published var cameraPermissionDenied: Bool = false
    @Published var hasScannedAlbums: Bool = false

    init() {
        // Check if first launch
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        self.isFirstLaunch = !hasLaunchedBefore

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
