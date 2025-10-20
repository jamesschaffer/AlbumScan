import AVFoundation
import UIKit
import Combine

class CameraManager: NSObject, ObservableObject {
    @Published var isProcessing = false
    @Published var capturedImage: UIImage?
    @Published var error: Error?
    @Published var scannedAlbum: Album?

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")

    override init() {
        super.init()
        setupSession()
    }

    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            self.session.beginConfiguration()

            defer {
                // Always commit configuration, even if setup fails
                self.session.commitConfiguration()
            }

            // Set session preset
            self.session.sessionPreset = .photo

            // Add video input
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
                  self.session.canAddInput(videoInput) else {
                print("Could not add video input")
                DispatchQueue.main.async {
                    self.error = NSError(domain: "CameraManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not add video input. Make sure you're running on a device with a camera."])
                }
                return
            }

            // Set camera zoom to 1x (default)
            do {
                try videoDevice.lockForConfiguration()
                videoDevice.videoZoomFactor = 1.0
                videoDevice.unlockForConfiguration()
            } catch {
                print("Could not set zoom factor: \(error)")
            }

            self.session.addInput(videoInput)

            // Add photo output
            guard self.session.canAddOutput(self.photoOutput) else {
                print("Could not add photo output")
                DispatchQueue.main.async {
                    self.error = NSError(domain: "CameraManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Could not add photo output."])
                }
                return
            }

            self.session.addOutput(self.photoOutput)
            self.photoOutput.isHighResolutionCaptureEnabled = false
        }
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            self?.session.startRunning()
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }

    func capturePhoto() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isProcessing = true
            }

            let settings = AVCapturePhotoSettings()
            settings.flashMode = .auto

            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.error = error
                self.isProcessing = false
            }
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            DispatchQueue.main.async {
                self.isProcessing = false
            }
            return
        }

        // Resize and crop to square
        let processedImage = processImage(image)

        DispatchQueue.main.async {
            self.capturedImage = processedImage

            // Send to API
            Task {
                await self.identifyAlbum(image: processedImage)
            }
        }
    }

    private func processImage(_ image: UIImage) -> UIImage {
        // Calculate the guide size matching the UI (screen width - 40px margins)
        let screenWidth = UIScreen.main.bounds.width
        let guideSize = screenWidth - 40

        // Calculate the ratio between guide size and image size
        let imageWidth = image.size.width
        let imageHeight = image.size.height

        // The camera captures full screen, so we need to crop to the center square
        // matching the guide dimensions
        let cropSize = min(imageWidth, imageHeight)
        let origin = CGPoint(
            x: (imageWidth - cropSize) / 2,
            y: (imageHeight - cropSize) / 2
        )

        let cropRect = CGRect(origin: origin, size: CGSize(width: cropSize, height: cropSize))

        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return image
        }

        let croppedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)

        // Resize to 1024x1024 for API
        let targetSize = CGSize(width: 1024, height: 1024)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { context in
            croppedImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        return resizedImage
    }

    private func identifyAlbum(image: UIImage) async {
        let totalStart = Date()
        print("⏱️ [TIMING] ========== STARTING ALBUM IDENTIFICATION ==========")
        print("🎵 [CameraManager] Starting album identification...")

        do {
            // Step 1: Claude API
            let claudeStart = Date()
            print("🎵 [CameraManager] Calling Claude API...")
            let response = try await ClaudeAPIService.shared.identifyAlbum(image: image)
            let claudeTime = Date().timeIntervalSince(claudeStart)
            print("⏱️ [TIMING] Claude API took: \(String(format: "%.2f", claudeTime))s")
            print("🎵 [CameraManager] API Response received - Album: \(response.albumTitle) by \(response.artistName)")

            // Step 2: Search MusicBrainz for MBID
            let mbStart = Date()
            print("🔍 [CameraManager] Searching MusicBrainz...")
            var musicbrainzID: String?
            var artworkData: (highRes: Data?, thumbnail: Data?)?
            var artworkRetrievalFailed = false

            do {
                if let mbid = try await MusicBrainzService.shared.searchAlbum(
                    artist: response.artistName,
                    album: response.albumTitle
                ) {
                    let mbTime = Date().timeIntervalSince(mbStart)
                    print("⏱️ [TIMING] MusicBrainz search took: \(String(format: "%.2f", mbTime))s")
                    musicbrainzID = mbid
                    print("✅ [CameraManager] Found MBID: \(mbid)")

                    // Step 3: Download artwork from Cover Art Archive
                    let artStart = Date()
                    print("🎨 [CameraManager] Downloading artwork...")
                    let artwork = await CoverArtService.shared.retrieveArtwork(mbid: mbid)
                    let artTime = Date().timeIntervalSince(artStart)
                    print("⏱️ [TIMING] Artwork download took: \(String(format: "%.2f", artTime))s")

                    if artwork.highRes != nil || artwork.thumbnail != nil {
                        artworkData = artwork
                        print("✅ [CameraManager] Artwork downloaded successfully")
                    } else {
                        print("⚠️ [CameraManager] No artwork available for this album")
                        artworkRetrievalFailed = true
                    }
                } else {
                    let mbTime = Date().timeIntervalSince(mbStart)
                    print("⏱️ [TIMING] MusicBrainz search took: \(String(format: "%.2f", mbTime))s (no results)")
                    print("⚠️ [CameraManager] Album not found on MusicBrainz")
                    artworkRetrievalFailed = true
                }
            } catch {
                print("⚠️ [CameraManager] Artwork retrieval error (non-blocking): \(error.localizedDescription)")
                artworkRetrievalFailed = true
            }

            // Save to CoreData (artwork failure doesn't block this)
            let saveStart = Date()
            print("🎵 [CameraManager] Saving to CoreData...")
            let savedAlbum = try PersistenceController.shared.saveAlbum(
                from: response,
                musicbrainzID: musicbrainzID,
                artworkData: artworkData,
                artworkRetrievalFailed: artworkRetrievalFailed
            )
            let saveTime = Date().timeIntervalSince(saveStart)
            print("⏱️ [TIMING] CoreData save took: \(String(format: "%.2f", saveTime))s")
            print("🎵 [CameraManager] Successfully saved to CoreData")

            // Set the scanned album to trigger navigation
            await MainActor.run {
                let totalTime = Date().timeIntervalSince(totalStart)
                print("⏱️ [TIMING] ========== TOTAL TIME: \(String(format: "%.2f", totalTime))s ==========")
                print("🎵 [CameraManager] Identification complete!")
                self.scannedAlbum = savedAlbum
                self.isProcessing = false
            }
        } catch {
            let totalTime = Date().timeIntervalSince(totalStart)
            print("⏱️ [TIMING] ========== FAILED AFTER: \(String(format: "%.2f", totalTime))s ==========")
            print("❌ [CameraManager] Error during identification: \(error.localizedDescription)")
            if let apiError = error as? APIError {
                print("❌ [CameraManager] API Error details: \(apiError)")
            }
            await MainActor.run {
                self.error = error
                self.isProcessing = false
            }
        }
    }
}
