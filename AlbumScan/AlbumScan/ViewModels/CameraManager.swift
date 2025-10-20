import AVFoundation
import UIKit
import Combine

class CameraManager: NSObject, ObservableObject {
    @Published var isProcessing = false
    @Published var capturedImage: UIImage?
    @Published var error: Error?

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
        // Crop to square and resize to 1024x1024
        let size = min(image.size.width, image.size.height)
        let origin = CGPoint(
            x: (image.size.width - size) / 2,
            y: (image.size.height - size) / 2
        )

        let cropRect = CGRect(origin: origin, size: CGSize(width: size, height: size))

        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return image
        }

        let croppedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)

        // Resize to 1024x1024
        let targetSize = CGSize(width: 1024, height: 1024)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { context in
            croppedImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        return resizedImage
    }

    private func identifyAlbum(image: UIImage) async {
        print("🎵 [CameraManager] Starting album identification...")
        do {
            print("🎵 [CameraManager] Calling Claude API...")
            let response = try await ClaudeAPIService.shared.identifyAlbum(image: image)
            print("🎵 [CameraManager] API Response received - Album: \(response.albumTitle) by \(response.artistName)")

            // Download album art if URL provided
            var artData: Data?
            if let artURL = response.albumArtURL,
               let url = URL(string: artURL) {
                print("🎵 [CameraManager] Downloading album art from: \(artURL)")
                artData = try? await downloadImage(from: url)
                print("🎵 [CameraManager] Album art download \(artData != nil ? "succeeded" : "failed")")
            }

            // Save to CoreData
            print("🎵 [CameraManager] Saving to CoreData...")
            _ = try PersistenceController.shared.saveAlbum(from: response, imageData: artData)
            print("🎵 [CameraManager] Successfully saved to CoreData")

            // TODO: Navigate to album details view
            // For now, just stop processing
            await MainActor.run {
                print("🎵 [CameraManager] Identification complete!")
                self.isProcessing = false
            }
        } catch {
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

    private func downloadImage(from url: URL) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
}
