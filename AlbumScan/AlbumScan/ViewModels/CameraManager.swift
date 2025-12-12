import AVFoundation
import UIKit
import Combine
import CoreData

class CameraManager: NSObject, ObservableObject {
    @Published var isProcessing = false
    @Published var isCaptureInitiated = false  // Disables button immediately, before loading screen
    @Published var capturedImage: UIImage?
    @Published var error: Error?
    @Published var scannedAlbum: Album?

    // Subscription managers (injected from CameraView)
    var subscriptionManager: SubscriptionManager?
    var scanLimitManager: ScanLimitManager?
    var appState: AppState?

    // Store framing guide coordinates for cropping
    var capturedGuideFrame: CGRect = .zero
    var previewLayerSize: CGSize = .zero

    /// Call this to store the framing guide position for later cropping
    /// Must pass the actual preview layer bounds, not screen bounds!
    func setupFramingGuide(screenSize: CGSize, previewBounds: CGSize) {
        let guideMargin: CGFloat = 20
        let guideSize = screenSize.width - (guideMargin * 2)

        // VERTICAL ADJUSTMENT: Shift guide up/down to fine-tune crop alignment
        // Use percentage of screen height to work across all devices
        // Positive = move crop DOWN, Negative = move crop UP
        let verticalAdjustmentPercent: CGFloat = 0.015
        let verticalAdjustment = screenSize.height * verticalAdjustmentPercent

        // Store guide frame (centered on screen with adjustment)
        capturedGuideFrame = CGRect(
            x: guideMargin,
            y: (screenSize.height - guideSize) / 2 + verticalAdjustment,
            width: guideSize,
            height: guideSize
        )

        // Store ACTUAL preview layer size (not screen size!)
        previewLayerSize = previewBounds
    }

    @Published var scanState: ScanState = .idle
    @Published var phase1Data: Phase1Response?
    @Published var phase2Data: Phase2Response?
    @Published var albumArtwork: UIImage?

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

            // Add video input - Try back camera first, then front camera (for Simulator)
            var videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)

            // If no back camera (Simulator), try front camera
            if videoDevice == nil {
                #if DEBUG
                print("⚠️ Back camera not available, trying front camera (Simulator)")
                #endif
                videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
            }

            guard let device = videoDevice,
                  let videoInput = try? AVCaptureDeviceInput(device: device),
                  self.session.canAddInput(videoInput) else {
                #if DEBUG
                print("❌ Could not add any video input")
                #endif
                DispatchQueue.main.async {
                    self.error = NSError(domain: "CameraManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not add video input. Make sure you're running on a device with a camera or in a Simulator with camera enabled."])
                }
                return
            }

            // Set camera zoom to 1x (default)
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = 1.0
                device.unlockForConfiguration()
            } catch {
                #if DEBUG
                print("Could not set zoom factor: \(error)")
                #endif
            }

            self.session.addInput(videoInput)

            #if DEBUG
            print("✅ Video input added successfully")
            #endif

            // Add photo output
            guard self.session.canAddOutput(self.photoOutput) else {
                #if DEBUG
                print("Could not add photo output")
                #endif
                DispatchQueue.main.async {
                    self.error = NSError(domain: "CameraManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Could not add photo output."])
                }
                return
            }

            self.session.addOutput(self.photoOutput)
            // Note: isHighResolutionCaptureEnabled deprecated in iOS 16
            // Using default behavior (no need to set maxPhotoDimensions for our use case)
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
        #if DEBUG
        print("📸 [CAPTURE] ========================================")
        print("📸 [CAPTURE] NEW SCAN STARTED")
        print("📸 [CAPTURE] ========================================")
        #endif

        // Disable button IMMEDIATELY to prevent double-tap
        isCaptureInitiated = true

        // Wait 0.25s for button press animation to complete before showing loading screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self = self else { return }

            // Clear previous state and set processing flag
            self.scannedAlbum = nil
            self.phase1Data = nil
            self.phase2Data = nil
            self.albumArtwork = nil
            self.capturedImage = nil
            self.error = nil
            self.scanState = .identifying  // For two-tier flow
            self.isProcessing = true       // For old flow
        }

        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            // Check if session is running before attempting capture
            guard self.session.isRunning else {
                #if DEBUG
                print("❌ Camera session is not running")
                #endif
                DispatchQueue.main.async {
                    self.error = NSError(domain: "CameraManager", code: -3, userInfo: [NSLocalizedDescriptionKey: "Camera session is not running. Please restart the app."])
                    self.isProcessing = false
                    self.isCaptureInitiated = false
                    self.scanState = .idle
                }
                return
            }

            // Check if photoOutput is connected to the session
            guard self.session.outputs.contains(self.photoOutput) else {
                #if DEBUG
                print("❌ Photo output is not connected to session")
                #endif
                DispatchQueue.main.async {
                    self.error = NSError(domain: "CameraManager", code: -4, userInfo: [NSLocalizedDescriptionKey: "Camera is not properly configured. Please restart the app."])
                    self.isProcessing = false
                    self.isCaptureInitiated = false
                    self.scanState = .idle
                }
                return
            }

            // Additional safety check: Verify photoOutput connection is valid
            guard self.photoOutput.connection(with: .video) != nil else {
                #if DEBUG
                print("❌ Photo output has no valid video connection")
                #endif
                DispatchQueue.main.async {
                    self.error = NSError(domain: "CameraManager", code: -5, userInfo: [NSLocalizedDescriptionKey: "Camera connection is invalid. Please restart the app."])
                    self.isProcessing = false
                    self.isCaptureInitiated = false
                    self.scanState = .idle
                }
                return
            }

            let settings = AVCapturePhotoSettings()

            // CRITICAL iPad Fix: Only set flash mode if device supports it
            // iPad cameras don't have flash, so setting flashMode causes crash
            if self.photoOutput.supportedFlashModes.contains(.auto) {
                settings.flashMode = .auto
                #if DEBUG
                print("📸 [CAPTURE] Flash set to auto (device supports flash)")
                #endif
            } else {
                // Device doesn't support flash (iPad) - leave at default (.off)
                #if DEBUG
                print("📸 [CAPTURE] Flash not supported on this device (iPad)")
                #endif
            }

            // Final safety check before capture
            guard self.session.isRunning, self.session.outputs.contains(self.photoOutput) else {
                #if DEBUG
                print("❌ Session state changed before capture")
                #endif
                DispatchQueue.main.async {
                    self.error = NSError(domain: "CameraManager", code: -6, userInfo: [NSLocalizedDescriptionKey: "Camera session was interrupted. Please try again."])
                    self.isProcessing = false
                    self.isCaptureInitiated = false
                    self.scanState = .idle
                }
                return
            }

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

            // Send to API (single-prompt flow for OpenAI)
            Task {
                await self.identifySinglePrompt(image: processedImage)
            }
        }
    }

    // MARK: - Image Processing Pipeline

    /// Complete image processing pipeline from camera capture to API-ready image
    private func processImage(_ image: UIImage) -> UIImage {
        #if DEBUG
        print("")
        print("═══ IMAGE PROCESSING PIPELINE ═══")
        print("📸 RAW: \(Int(image.size.width))x\(Int(image.size.height)) @\(image.scale)x scale")
        if let jpegData = image.jpegData(compressionQuality: 0.6) {
            print("📸 RAW JPEG (0.6 quality): \(jpegData.count / 1024)KB")
        }
        #endif

        // STEP 1: Fix orientation (CRITICAL - do this first!)
        guard let orientedImage = fixImageOrientation(image: image) else {
            #if DEBUG
            print("❌ Failed to fix image orientation")
            #endif
            return image
        }

        // STEP 2: Convert guide frame to image coordinates
        let imageCropRect = convertGuideToImageCoordinates(
            guideFrame: capturedGuideFrame,
            imageSize: orientedImage.size,
            previewLayerSize: previewLayerSize
        )

        // STEP 3: Crop to guide with 5px margin
        guard let croppedImage = cropToGuide(image: orientedImage, cropRect: imageCropRect) else {
            #if DEBUG
            print("❌ Failed to crop image")
            #endif
            return orientedImage
        }

        #if DEBUG
        print("✂️  CROPPED: \(Int(croppedImage.size.width))x\(Int(croppedImage.size.height)) @\(croppedImage.scale)x scale")
        if let jpegData = croppedImage.jpegData(compressionQuality: 0.6) {
            print("✂️  CROPPED JPEG (0.6 quality): \(jpegData.count / 1024)KB")
        }
        #endif

        // STEP 4: Resize to 1024×1024
        guard let finalImage = resizeImage(image: croppedImage, targetSize: CGSize(width: 1024, height: 1024)) else {
            #if DEBUG
            print("❌ Failed to resize image")
            #endif
            return croppedImage
        }

        #if DEBUG
        print("📐 RESIZED: \(Int(finalImage.size.width))x\(Int(finalImage.size.height)) @\(finalImage.scale)x scale")
        if let jpegData = finalImage.jpegData(compressionQuality: 0.6) {
            print("📐 RESIZED JPEG (0.6 quality): \(jpegData.count / 1024)KB")
        }
        print("═══════════════════════════════════")
        print("")
        #endif
        return finalImage
    }

    /// Normalizes image orientation so pixel data matches visual display
    /// Preserves original scale during orientation fix
    private func fixImageOrientation(image: UIImage) -> UIImage? {
        // If image is already correctly oriented, return it
        if image.imageOrientation == .up {
            return image
        }

        // Render the image in its correct orientation
        // Note: This preserves the original image.scale, which is fine here
        // The resizeImage() function will normalize to @1x later
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return normalizedImage
    }

    /// Converts on-screen framing guide rectangle to actual image pixel coordinates
    private func convertGuideToImageCoordinates(
        guideFrame: CGRect,
        imageSize: CGSize,
        previewLayerSize: CGSize
    ) -> CGRect {
        // With .resizeAspectFill, determine which dimension the preview fills by
        let screenAspect = previewLayerSize.width / previewLayerSize.height
        let imageAspect = imageSize.width / imageSize.height

        var scale: CGFloat
        var offsetX: CGFloat = 0
        var offsetY: CGFloat = 0

        if imageAspect > screenAspect {
            // Image is WIDER than screen - preview fills by HEIGHT, crops left/right
            scale = imageSize.height / previewLayerSize.height
            let visibleImageWidth = previewLayerSize.width * scale
            offsetX = (imageSize.width - visibleImageWidth) / 2
        } else {
            // Image is TALLER than screen - preview fills by WIDTH, crops top/bottom
            scale = imageSize.width / previewLayerSize.width
            let visibleImageHeight = previewLayerSize.height * scale
            offsetY = (imageSize.height - visibleImageHeight) / 2
        }

        // Apply scale to guide dimensions and ADD the crop offset
        return CGRect(
            x: offsetX + (guideFrame.origin.x * scale),
            y: offsetY + (guideFrame.origin.y * scale),
            width: guideFrame.width * scale,
            height: guideFrame.height * scale
        )
    }

    /// Crops image to specified rectangle with 5px inward margin
    private func cropToGuide(image: UIImage, cropRect: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        // Apply 5px margin inward
        let margin: CGFloat = 5.0
        let adjustedRect = CGRect(
            x: cropRect.origin.x + margin,
            y: cropRect.origin.y + margin,
            width: cropRect.width - (margin * 2),
            height: cropRect.height - (margin * 2)
        )

        // Ensure crop rect is within image bounds
        let boundedRect = adjustedRect.intersection(
            CGRect(origin: .zero, size: image.size)
        )

        // Crop the image
        guard let croppedCGImage = cgImage.cropping(to: boundedRect) else {
            return nil
        }

        return UIImage(
            cgImage: croppedCGImage,
            scale: image.scale,
            orientation: image.imageOrientation
        )
    }

    /// Resizes image to target size for API upload
    /// CRITICAL: Uses explicit @1x scale to avoid bloated file sizes
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        // 🚨 BUG FIX: UIGraphicsImageRenderer defaults to device scale (@2x or @3x)
        // This causes 1024x1024 to become 2048x2048 or 3072x3072 internally!
        // Force @1x scale to get true 1024x1024 pixel dimensions
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0  // ← CRITICAL: Force @1x scale

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    // OLD SINGLE-TIER FLOW - Disabled (useTwoTierFlow = true)
    // Kept for reference only
    /*
    private func identifyAlbum(image: UIImage) async {
        let totalStart = Date()
        print("⏱️ [TIMING] ========== STARTING ALBUM IDENTIFICATION ==========")
        print("🎵 [CameraManager] Starting album identification...")

        do {
            // Step 1: Claude API
            let claudeStart = Date()
            print("🎵 [CameraManager] Calling Claude API...")
            await MainActor.run {
            }
            let response = try await ClaudeAPIService.shared.identifyAlbum(image: image)
            let claudeTime = Date().timeIntervalSince(claudeStart)
            print("⏱️ [TIMING] Claude API took: \(String(format: "%.2f", claudeTime))s")
            print("🎵 [CameraManager] API Response received - Album: \(response.albumTitle) by \(response.artistName)")

            // Advance to parsing stage
            await MainActor.run {
            }

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

                    // Advance to artwork download stage
                    await MainActor.run {
                    }

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

                    // Still advance to artwork stage (will skip download)
                    await MainActor.run {
                    }
                }
            } catch {
                print("⚠️ [CameraManager] Artwork retrieval error (non-blocking): \(error.localizedDescription)")
                artworkRetrievalFailed = true

                // Still advance to artwork stage
                await MainActor.run {
                }
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
    */

    // MARK: - Two-Tier Flow (New)

    private func identifyAlbumTwoTier(image: UIImage) async {
        let totalStart = Date()
        print("⏱️ [TWO-TIER] ========== STARTING TWO-TIER IDENTIFICATION ==========")

        do {
            // PHASE 1A: Vision Extraction (NO web search)
            await MainActor.run {
                self.scanState = .identifying
            }

            let phase1AStart = Date()
            print("🔍 [FOUR-PHASE 1A] Starting vision extraction...")
            let phase1AResponse = try await LLMServiceFactory.getService().executePhase1A(image: image)
            let phase1ATime = Date().timeIntervalSince(phase1AStart)
            print("⏱️ [TIMING] Phase 1A took: \(String(format: "%.2f", phase1ATime))s")
            print("📝 [FOUR-PHASE 1A] Extracted text: \"\(phase1AResponse.extractedText)\"")
            print("📝 [FOUR-PHASE 1A] Description: \"\(phase1AResponse.albumDescription.prefix(100))...\"")

            // PHASE 1B: Web Search Mapping (WITH web search)
            let phase1BStart = Date()
            print("🔍 [FOUR-PHASE 1B] Starting web search mapping...")
            let phase1Response = try await LLMServiceFactory.getService().executePhase1B(phase1AData: phase1AResponse)
            let phase1BTime = Date().timeIntervalSince(phase1BStart)
            print("⏱️ [TIMING] Phase 1B took: \(String(format: "%.2f", phase1BTime))s")

            // Check if Phase 1B succeeded
            guard phase1Response.success,
                  let artistName = phase1Response.artistName,
                  let albumTitle = phase1Response.albumTitle else {
                print("❌ [FOUR-PHASE 1B] Identification failed")
                await MainActor.run {
                    self.scanState = .identificationFailed
                    self.error = NSError(domain: "CameraManager", code: -100, userInfo: [NSLocalizedDescriptionKey: "Could not identify album"])
                    self.isProcessing = false
                }
                return
            }

            let totalPhase1Time = Date().timeIntervalSince(phase1AStart)
            print("✅ [FOUR-PHASE 1A+1B] Identified: \(albumTitle) by \(artistName)")
            print("⏱️ [TIMING] Total Phase 1A+1B: \(String(format: "%.2f", totalPhase1Time))s")

            // Store Phase 1 data (but keep scanState as .identifying until artwork ready)
            await MainActor.run {
                self.phase1Data = phase1Response
            }

            // Check cache for existing album with completed Phase 2
            let cachedAlbum = self.checkCachedAlbum(artistName: artistName, albumTitle: albumTitle)

            // Check if we can use cached Phase 2 review
            let shouldSkipPhase2 = cachedAlbum?.phase2Completed == true
            if shouldSkipPhase2 {
                print("💾 [CACHE] Using cached Phase 2 review for \(albumTitle)")
            }

            // OPTIMIZATION: Parallelize artwork fetch and Phase 2 review
            print("🚀 [OPTIMIZATION] Starting artwork fetch and Phase 2 in parallel...")
            let parallelStart = Date()

            async let artworkTask = self.executeArtworkFetch(
                artistName: artistName,
                albumTitle: albumTitle
            )

            // Only run Phase 2 if not cached
            async let phase2Task = shouldSkipPhase2
                ? (response: cachedAlbum?.toPhase2Response(), failed: false)
                : self.executePhase2(
                    artistName: artistName,
                    albumTitle: albumTitle,
                    releaseYear: phase1Response.releaseYear ?? "Unknown",
                    genres: phase1Response.genres ?? [],
                    recordLabel: phase1Response.recordLabel ?? "Unknown"
                  )

            // Wait for artwork FIRST (for UX - need artwork before showing "We found" screen)
            let finalArtworkResult = await artworkTask
            print("⏱️ [TIMING] Artwork ready - transitioning to .identified state")

            // Transition to .identified state NOW (artwork is ready)
            await MainActor.run {
                self.scanState = .identified
            }

            // Stay in .identified for 1.0 second to show "We found [album]"
            // Phase 2 continues running in background during this time
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1.0s

            // Now wait for Phase 2 to complete (if not already done)
            let finalPhase2Result = await phase2Task

            let parallelTime = Date().timeIntervalSince(parallelStart)
            print("⏱️ [TIMING] Parallel execution (artwork + Phase 2) took: \(String(format: "%.2f", parallelTime))s")

            // Transition to loading review state
            await MainActor.run {
                self.scanState = .loadingReview
            }

            // Save to CoreData (artwork result from earlier fetch)
            let savedAlbum = try await self.saveTwoTierAlbum(
                phase1: phase1Response,
                phase2: finalPhase2Result.response,
                phase2Failed: finalPhase2Result.failed,
                musicbrainzID: finalArtworkResult.mbid,
                artworkData: finalArtworkResult.data,
                artworkFailed: finalArtworkResult.failed,
                relations: finalArtworkResult.relations
            )

            // Complete
            await MainActor.run {
                let totalTime = Date().timeIntervalSince(totalStart)
                print("⏱️ [TIMING] ========== TWO-TIER TOTAL: \(String(format: "%.2f", totalTime))s ==========")
                print("✅ [TWO-TIER] Setting scannedAlbum to: \(savedAlbum.albumTitle) by \(savedAlbum.artistName)")
                self.scanState = .complete
                self.scannedAlbum = savedAlbum
                self.isProcessing = false

                // Increment scan count (only if not subscribed)
                if let scanLimitManager = self.scanLimitManager,
                   let subscriptionManager = self.subscriptionManager,
                   !subscriptionManager.isSubscribed {
                    scanLimitManager.incrementScanCount()
                    #if DEBUG
                    print("📊 [Scan] Incremented scan count - \(scanLimitManager.remainingFreeScans) remaining")
                    #endif
                }
            }

        } catch {
            let totalTime = Date().timeIntervalSince(totalStart)
            print("⏱️ [TIMING] ========== TWO-TIER FAILED AFTER: \(String(format: "%.2f", totalTime))s ==========")
            print("❌ [TWO-TIER] Error: \(error.localizedDescription)")
            await MainActor.run {
                self.error = error
                self.scanState = .identificationFailed
                self.isProcessing = false
            }
        }
    }

    // MARK: - Single-Prompt Flow (New - OpenAI Only)

    private func identifySinglePrompt(image: UIImage) async {
        let totalStart = Date()
        print("")
        print("═══════════════════════════════════════════════════════════")
        print("🚀 [TIMING] SCAN STARTED")
        print("═══════════════════════════════════════════════════════════")

        // Reset deep cut flag
        await MainActor.run {
        }

        do {
            // ID CALL 1: Single-prompt identification (Phase 1 + 2 internal recognition)
            await MainActor.run {
                self.scanState = .identifying
            }

            let call1Start = Date()
            let cumulativeAtCall1Start = Date().timeIntervalSince(totalStart)
            print("")
            print("┌─ 🔍 [ID CALL 1] Single-Prompt Identification")
            print("│  ⏱️  Start: +\(String(format: "%.2f", cumulativeAtCall1Start))s (cumulative)")

            // Get the configured LLM service with provider routing
            #if DEBUG
            let llmService = LLMServiceFactory.getService(for: appState?.selectedProvider ?? .openAI)
            #else
            let llmService = LLMServiceFactory.getService()
            #endif

            let identificationResponse = try await llmService.executeSinglePromptIdentification(image: image)
            let call1Time = Date().timeIntervalSince(call1Start)
            let cumulativeAfterCall1 = Date().timeIntervalSince(totalStart)
            print("│  ✅ Complete")
            print("│  ⏱️  Duration: \(String(format: "%.2f", call1Time))s")
            print("└─ ⏱️  Cumulative: +\(String(format: "%.2f", cumulativeAfterCall1))s")

            var finalArtistName: String
            var finalAlbumTitle: String
            var finalReleaseYear: String
            var finalGenres: [String]
            var finalRecordLabel: String

            // Handle the three possible outcomes
            switch identificationResponse {
            case .success(let successResponse):
                // High/Medium confidence - no search needed!
                print("✅ [ID Call 1] Success with \(successResponse.confidence) confidence")
                print("✅ [ID Call 1] Identified: \(successResponse.albumTitle) by \(successResponse.artistName)")

                finalArtistName = successResponse.artistName
                finalAlbumTitle = successResponse.albumTitle
                finalReleaseYear = successResponse.releaseYear
                finalGenres = successResponse.genres
                finalRecordLabel = successResponse.recordLabel

            case .searchNeeded(let searchRequest):
                // Low confidence - need web search (deep cut!)
                print("")
                print("┌─ 🔍 [SEARCH GATE] Validation Check")
                print("│  Reason: \(searchRequest.searchRequest.reason)")
                print("│  Query: \(searchRequest.searchRequest.query)")

                // SEARCH GATE: Validate if search is worth attempting
                let extractedText = searchRequest.searchRequest.observation.extractedText
                let textConfidence = searchRequest.searchRequest.observation.textConfidence
                let meaningfulChars = extractedText.filter { !$0.isWhitespace }.count

                print("│  Text: '\(extractedText)'")
                print("│  Chars: \(meaningfulChars) | Confidence: \(textConfidence)")

                guard meaningfulChars >= 3 && textConfidence != "low" else {
                    print("│  ⛔ BLOCKED - Insufficient text data")
                    print("│  Criteria: 3+ chars AND medium/high confidence")
                    print("└─ ❌ Search Gate Failed")

                    await MainActor.run {
                        self.scanState = .identificationFailed
                        self.error = NSError(domain: "CameraManager", code: -100, userInfo: [NSLocalizedDescriptionKey: "Unable to identify - album cover has insufficient readable text"])
                        self.isProcessing = false
                        self.isCaptureInitiated = false
                    }
                    return
                }

                print("│  ✅ PASSED - Text sufficient for search")
                print("└─ ⏱️  Cumulative: +\(String(format: "%.2f", Date().timeIntervalSince(totalStart)))s")

                // Trigger "deep cut" message in UI
                await MainActor.run {
                }

                // ID CALL 2: Search finalization
                let call2Start = Date()
                let cumulativeAtCall2Start = Date().timeIntervalSince(totalStart)
                print("")
                print("┌─ 🔍 [ID CALL 2] Search Finalization (with web search)")
                print("│  ⏱️  Start: +\(String(format: "%.2f", cumulativeAtCall2Start))s (cumulative)")
                print("│  Query: \(searchRequest.searchRequest.query)")

                let searchResponse = try await llmService.executeSearchFinalization(
                    image: image,
                    searchRequest: searchRequest.searchRequest
                )
                let call2Time = Date().timeIntervalSince(call2Start)
                let cumulativeAfterCall2 = Date().timeIntervalSince(totalStart)

                // Handle Call 2 result
                switch searchResponse {
                case .success(let successResponse):
                    print("│  ✅ Complete")
                    print("│  Result: \(successResponse.albumTitle) by \(successResponse.artistName)")
                    print("│  ⏱️  Duration: \(String(format: "%.2f", call2Time))s")
                    print("└─ ⏱️  Cumulative: +\(String(format: "%.2f", cumulativeAfterCall2))s")

                    finalArtistName = successResponse.artistName
                    finalAlbumTitle = successResponse.albumTitle
                    finalReleaseYear = successResponse.releaseYear
                    finalGenres = successResponse.genres
                    finalRecordLabel = successResponse.recordLabel

                case .unresolved(let unresolvedResponse):
                    print("❌ [ID Call 2] Could not resolve: \(unresolvedResponse.errorMessage)")
                    await MainActor.run {
                        self.scanState = .identificationFailed
                        self.error = NSError(domain: "CameraManager", code: -100, userInfo: [NSLocalizedDescriptionKey: unresolvedResponse.errorMessage])
                        self.isProcessing = false
                    }
                    return

                case .searchNeeded:
                    // This shouldn't happen in Call 2
                    print("❌ [ID Call 2] Unexpected searchNeeded response")
                    await MainActor.run {
                        self.scanState = .identificationFailed
                        self.error = NSError(domain: "CameraManager", code: -101, userInfo: [NSLocalizedDescriptionKey: "Unexpected response from search"])
                        self.isProcessing = false
                    }
                    return
                }

            case .unresolved(let unresolvedResponse):
                // Couldn't identify even with available data
                print("❌ [ID Call 1] Unresolved: \(unresolvedResponse.errorMessage)")
                await MainActor.run {
                    self.scanState = .identificationFailed
                    self.error = NSError(domain: "CameraManager", code: -100, userInfo: [NSLocalizedDescriptionKey: unresolvedResponse.errorMessage])
                    self.isProcessing = false
                }
                return
            }

            let totalIDTime = Date().timeIntervalSince(call1Start)
            print("✅ [SINGLE-PROMPT ID] Identified: \(finalAlbumTitle) by \(finalArtistName)")
            print("⏱️ [TIMING] Total ID time: \(String(format: "%.2f", totalIDTime))s")

            // Store Phase 1 data for compatibility (convert to Phase1Response format)
            let phase1Response = Phase1Response(
                success: true,
                artistName: finalArtistName,
                albumTitle: finalAlbumTitle,
                releaseYear: finalReleaseYear,
                genres: finalGenres,
                recordLabel: finalRecordLabel,
                errorMessage: nil
            )

            await MainActor.run {
                self.phase1Data = phase1Response
            }

            // Check cache for existing album with completed Phase 2
            let cachedAlbum = self.checkCachedAlbum(artistName: finalArtistName, albumTitle: finalAlbumTitle)

            // Check if we can use cached Phase 2 review
            let shouldSkipPhase2 = cachedAlbum?.phase2Completed == true
            if shouldSkipPhase2 {
                print("💾 [CACHE] Using cached Phase 2 review for \(finalAlbumTitle)")
            }

            // OPTIMIZATION: Parallelize artwork fetch and Phase 2 review
            let parallelStart = Date()
            let cumulativeAtParallelStart = Date().timeIntervalSince(totalStart)
            print("")
            print("┌─ 🚀 [PARALLEL EXECUTION] Artwork + Phase 2")
            print("│  ⏱️  Start: +\(String(format: "%.2f", cumulativeAtParallelStart))s (cumulative)")

            async let artworkTask = self.executeArtworkFetch(
                artistName: finalArtistName,
                albumTitle: finalAlbumTitle
            )

            // Only run Phase 2 if not cached
            async let phase2Task = shouldSkipPhase2
                ? (response: cachedAlbum?.toPhase2Response(), failed: false)
                : self.executePhase2(
                    artistName: finalArtistName,
                    albumTitle: finalAlbumTitle,
                    releaseYear: finalReleaseYear,
                    genres: finalGenres,
                    recordLabel: finalRecordLabel
                  )

            // Wait for artwork FIRST (for UX - need artwork before showing "We found" screen)
            let artworkWaitStart = Date()
            let finalArtworkResult = await artworkTask
            let artworkWaitTime = Date().timeIntervalSince(artworkWaitStart)
            let cumulativeAfterArtwork = Date().timeIntervalSince(totalStart)
            print("│  ✅ Artwork ready (waited \(String(format: "%.2f", artworkWaitTime))s)")
            print("│  ⏱️  Cumulative: +\(String(format: "%.2f", cumulativeAfterArtwork))s")

            // Transition to .identified state NOW (artwork is ready)
            await MainActor.run {
                self.scanState = .identified
            }

            // Stay in .identified for 1.0 second to show "We found [album]"
            // Phase 2 continues running in background during this time
            print("│  💤 UI delay: 1.0s (Phase 2 continues in background)")
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1.0s

            // Now wait for Phase 2 to complete (if not already done)
            let phase2WaitStart = Date()
            let finalPhase2Result = await phase2Task
            let phase2WaitTime = Date().timeIntervalSince(phase2WaitStart)
            let cumulativeAfterPhase2 = Date().timeIntervalSince(totalStart)

            if phase2WaitTime < 0.1 {
                print("│  ⚡ Phase 2 already complete (finished during UI delay)")
            } else {
                print("│  ✅ Phase 2 ready (waited \(String(format: "%.2f", phase2WaitTime))s)")
            }

            let parallelTime = Date().timeIntervalSince(parallelStart)
            print("│  ⏱️  Total parallel time: \(String(format: "%.2f", parallelTime))s")
            print("└─ ⏱️  Cumulative: +\(String(format: "%.2f", cumulativeAfterPhase2))s")

            // Transition to loading review state
            await MainActor.run {
                self.scanState = .loadingReview
            }

            // Save to CoreData
            let saveStart = Date()
            let cumulativeAtSaveStart = Date().timeIntervalSince(totalStart)
            print("")
            print("┌─ 💾 [SAVE] CoreData")
            print("│  ⏱️  Start: +\(String(format: "%.2f", cumulativeAtSaveStart))s (cumulative)")

            let savedAlbum = try await self.saveTwoTierAlbum(
                phase1: phase1Response,
                phase2: finalPhase2Result.response,
                phase2Failed: finalPhase2Result.failed,
                musicbrainzID: finalArtworkResult.mbid,
                artworkData: finalArtworkResult.data,
                artworkFailed: finalArtworkResult.failed,
                relations: finalArtworkResult.relations
            )

            let saveTime = Date().timeIntervalSince(saveStart)
            let totalTime = Date().timeIntervalSince(totalStart)
            print("│  ✅ Complete")
            print("│  ⏱️  Duration: \(String(format: "%.2f", saveTime))s")
            print("└─ ⏱️  Cumulative: +\(String(format: "%.2f", totalTime))s")

            // Complete
            await MainActor.run {
                print("")
                print("═══════════════════════════════════════════════════════════")
                print("✅ [COMPLETE] SCAN FINISHED")
                print("   Album: \(savedAlbum.albumTitle)")
                print("   Artist: \(savedAlbum.artistName)")
                print("   ⏱️  TOTAL TIME: \(String(format: "%.2f", totalTime))s")
                print("═══════════════════════════════════════════════════════════")
                print("")
                self.scanState = .complete
                self.scannedAlbum = savedAlbum
                self.isProcessing = false

                // Increment scan count (only if not subscribed)
                if let scanLimitManager = self.scanLimitManager,
                   let subscriptionManager = self.subscriptionManager,
                   !subscriptionManager.isSubscribed {
                    scanLimitManager.incrementScanCount()
                    #if DEBUG
                    print("📊 [Scan] Incremented scan count - \(scanLimitManager.remainingFreeScans) remaining")
                    #endif
                }
            }

        } catch {
            let totalTime = Date().timeIntervalSince(totalStart)
            print("⏱️ [TIMING] ========== SINGLE-PROMPT FAILED AFTER: \(String(format: "%.2f", totalTime))s ==========")
            print("❌ [SINGLE-PROMPT] Error: \(error.localizedDescription)")
            await MainActor.run {
                self.error = error
                self.scanState = .identificationFailed
                self.isProcessing = false
            }
        }
    }

    private func executePhase2(artistName: String, albumTitle: String, releaseYear: String, genres: [String], recordLabel: String) async -> (response: Phase2Response?, failed: Bool) {
        let phase2Start = Date()

        print("   ├─ 📝 [PHASE 2] Review Generation")

        do {
            #if DEBUG
            let llmService = LLMServiceFactory.getService(for: appState?.selectedProvider ?? .openAI)
            #else
            let llmService = LLMServiceFactory.getService()
            #endif
            let phase2Response = try await llmService.generateReviewPhase2(
                artistName: artistName,
                albumTitle: albumTitle,
                releaseYear: releaseYear,
                genres: genres,
                recordLabel: recordLabel
            )
            let phase2Time = Date().timeIntervalSince(phase2Start)
            print("   │  ✅ Complete (\(String(format: "%.2f", phase2Time))s)")

            await MainActor.run {
                self.phase2Data = phase2Response
            }

            return (phase2Response, false)
        } catch {
            print("❌ [TWO-TIER Phase2] Review generation failed: \(error.localizedDescription)")
            return (nil, true)
        }
    }

    private func executeArtworkFetch(artistName: String, albumTitle: String) async -> (mbid: String?, data: (highRes: Data?, thumbnail: Data?)?, failed: Bool, relations: ReleaseGroupRelationsResult?) {
        let artStart = Date()
        print("   ├─ 🎨 [ARTWORK] Fetch")

        do {
            // Step 1: MusicBrainz search
            let mbStart = Date()
            print("   │  ├─ 🔍 MusicBrainz search...")
            if let mbid = try await MusicBrainzService.shared.searchAlbum(artist: artistName, album: albumTitle) {
                let mbTime = Date().timeIntervalSince(mbStart)
                print("   │  │  ✅ Found MBID (\(String(format: "%.2f", mbTime))s)")

                // Step 2: Cover Art Archive download (separate service, no rate limit issue)
                let artDownloadStart = Date()
                print("   │  └─ 📥 Cover Art download...")
                let artwork = await CoverArtService.shared.retrieveArtwork(mbid: mbid)
                let artDownloadTime = Date().timeIntervalSince(artDownloadStart)

                // Step 3: Fetch release-group relations (singles + review URLs)
                // Natural delay from Cover Art download typically satisfies 1 req/sec rate limit
                let relationsStart = Date()
                print("   │  └─ 🔗 MusicBrainz relations...")
                var relations: ReleaseGroupRelationsResult?
                do {
                    relations = try await MusicBrainzService.shared.fetchReleaseGroupRelations(mbid: mbid)
                    let relationsTime = Date().timeIntervalSince(relationsStart)
                    print("   │     ✅ Relations fetched (\(String(format: "%.2f", relationsTime))s)")
                    print("   │     Singles: \(relations?.singles.count ?? 0), Reviews: \(relations?.reviewURLs.count ?? 0)")
                } catch {
                    print("   │     ⚠️ Relations fetch failed: \(error.localizedDescription)")
                    // Non-blocking - continue without relations
                }

                let artTime = Date().timeIntervalSince(artStart)

                if artwork.highRes != nil || artwork.thumbnail != nil {
                    print("   │     ✅ Downloaded (\(String(format: "%.2f", artDownloadTime))s)")
                    print("   │  Total: \(String(format: "%.2f", artTime))s")

                    // Update UI with artwork
                    if let highResData = artwork.highRes, let image = UIImage(data: highResData) {
                        await MainActor.run {
                            self.albumArtwork = image
                        }
                    }

                    return (mbid, artwork, false, relations)
                } else {
                    print("⚠️ [TWO-TIER Artwork] No artwork available")
                    return (mbid, nil, true, relations)
                }
            } else {
                print("⚠️ [TWO-TIER Artwork] Album not found on MusicBrainz")
                return (nil, nil, true, nil)
            }
        } catch {
            print("❌ [TWO-TIER Artwork] Error: \(error.localizedDescription)")
            return (nil, nil, true, nil)
        }
    }

    private func saveTwoTierAlbum(phase1: Phase1Response, phase2: Phase2Response?, phase2Failed: Bool, musicbrainzID: String?, artworkData: (highRes: Data?, thumbnail: Data?)?, artworkFailed: Bool, relations: ReleaseGroupRelationsResult?) async throws -> Album {
        print("💾 [TWO-TIER Save] Saving to CoreData...")

        // This will need a new save function in PersistenceController
        // For now, we'll create a temporary implementation
        let album = Album(context: PersistenceController.shared.container.viewContext)
        album.id = UUID()
        album.scannedDate = Date()

        // Phase 1 data
        album.artistName = phase1.artistName ?? "Unknown"
        album.albumTitle = phase1.albumTitle ?? "Unknown"
        album.releaseYear = phase1.releaseYear
        album.genres = phase1.genres ?? []
        album.recordLabel = phase1.recordLabel
        album.phase1Completed = true

        // Phase 2 data
        if let phase2 = phase2 {
            album.contextSummary = phase2.contextSummary
            album.contextBulletPoints = phase2.contextBullets
            album.rating = phase2.rating
            album.recommendation = phase2.recommendation
            album.phase2Completed = true
            album.phase2Failed = false
        } else {
            album.contextSummary = "Review temporarily unavailable"
            album.contextBulletPoints = []
            album.rating = 0.0
            album.recommendation = "SKIP"
            album.phase2Completed = false
            album.phase2Failed = phase2Failed
            album.phase2LastAttempt = Date()
        }

        // MusicBrainz relations data (singles as key tracks, review URLs)
        if let relations = relations {
            // Use singles from MusicBrainz as key tracks (replaces LLM-generated)
            album.keyTracks = relations.singles
            album.reviewURLs = relations.reviewURLs
            print("💾 [TWO-TIER Save] Key tracks from MB: \(relations.singles)")
            print("💾 [TWO-TIER Save] Review URLs: \(relations.reviewURLs)")
        } else {
            // Fallback to LLM key tracks if MusicBrainz relations unavailable
            album.keyTracks = phase2?.keyTracks ?? []
            album.reviewURLs = []
        }

        // Artwork data
        album.musicbrainzID = musicbrainzID
        album.albumArtHighResData = artworkData?.highRes
        album.albumArtThumbnailData = artworkData?.thumbnail
        album.albumArtRetrievalFailed = artworkFailed
        album.artworkLoaded = !artworkFailed

        try PersistenceController.shared.container.viewContext.save()
        print("✅ [TWO-TIER Save] Saved successfully")

        return album
    }

    // MARK: - Caching Helper

    private func checkCachedAlbum(artistName: String, albumTitle: String) -> Album? {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<Album> = Album.fetchRequest()

        // Match on artist name and album title (case-insensitive)
        fetchRequest.predicate = NSPredicate(
            format: "artistName ==[c] %@ AND albumTitle ==[c] %@",
            artistName,
            albumTitle
        )
        fetchRequest.fetchLimit = 1

        do {
            let results = try context.fetch(fetchRequest)
            if let existing = results.first {
                print("📦 [CACHE] Found existing album: \(albumTitle) by \(artistName)")
                print("📦 [CACHE] Phase2 completed: \(existing.phase2Completed), Phase2 failed: \(existing.phase2Failed)")
                return existing
            }
        } catch {
            print("❌ [CACHE] Error checking cache: \(error.localizedDescription)")
        }

        print("📦 [CACHE] No cached album found")
        return nil
    }
}
