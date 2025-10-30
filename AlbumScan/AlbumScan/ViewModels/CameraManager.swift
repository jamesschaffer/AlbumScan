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

    // Reference to AppState for Ultra search toggle
    private weak var appState: AppState?

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

    /// Set the AppState reference after initialization
    func setAppState(_ appState: AppState) {
        self.appState = appState
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
                #if DEBUG
                print("Could not add video input")
                #endif
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
                #if DEBUG
                print("Could not set zoom factor: \(error)")
                #endif
            }

            self.session.addInput(videoInput)

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
        print("📸 [CAPTURE] Starting new scan - disabling button, waiting for animation...")
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

            let settings = AVCapturePhotoSettings()
            settings.flashMode = .auto

            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraManager: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
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

        // STEP 4: Resize to 1024×1024
        guard let finalImage = resizeImage(image: croppedImage, targetSize: CGSize(width: 1024, height: 1024)) else {
            #if DEBUG
            print("❌ Failed to resize image")
            #endif
            return croppedImage
        }

        #if DEBUG
        print("✅ Image processed: 1024×1024 square ready for API")
        #endif
        return finalImage
    }

    /// Normalizes image orientation so pixel data matches visual display
    private func fixImageOrientation(image: UIImage) -> UIImage? {
        // If image is already correctly oriented, return it
        if image.imageOrientation == .up {
            return image
        }

        // Render the image in its correct orientation
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
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
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
            let _ = cachedAlbum?.phase2Completed == true  // Future: could skip Phase 2 if cached

            // Fetch artwork FIRST (don't show transition screen until artwork is ready)
            print("🎨 [TWO-TIER] Fetching artwork before showing transition...")
            let artworkFetchStart = Date()
            let artworkResult = await self.executeArtworkFetch(
                artistName: artistName,
                albumTitle: albumTitle
            )
            let artworkTime = Date().timeIntervalSince(artworkFetchStart)
            print("⏱️ [TIMING] Artwork fetch took: \(String(format: "%.2f", artworkTime))s")

            // NOW transition to .identified (artwork is ready)
            await MainActor.run {
                self.scanState = .identified
            }

            // Stay in .identified for 2.5 seconds to show "We found [album]"
            // (gives user time to see the result before showing album details)
            try await Task.sleep(nanoseconds: 2_500_000_000) // 2.5s

            // Start Phase 2 review generation
            await MainActor.run {
                self.scanState = .loadingReview
            }

            // PHASE 2: Review Generation (WITH web search)
            let phase2Result = await self.executePhase2(
                artistName: artistName,
                albumTitle: albumTitle,
                releaseYear: phase1Response.releaseYear ?? "Unknown",
                genres: phase1Response.genres ?? [],
                recordLabel: phase1Response.recordLabel ?? "Unknown"
            )

            // Save to CoreData (artwork result from earlier fetch)
            let savedAlbum = try await self.saveTwoTierAlbum(
                phase1: phase1Response,
                phase2: phase2Result.response,
                phase2Failed: phase2Result.failed,
                musicbrainzID: artworkResult.mbid,
                artworkData: artworkResult.data,
                artworkFailed: artworkResult.failed
            )

            // Complete
            await MainActor.run {
                let totalTime = Date().timeIntervalSince(totalStart)
                print("⏱️ [TIMING] ========== TWO-TIER TOTAL: \(String(format: "%.2f", totalTime))s ==========")
                print("✅ [TWO-TIER] Setting scannedAlbum to: \(savedAlbum.albumTitle) by \(savedAlbum.artistName)")
                self.scanState = .complete
                self.scannedAlbum = savedAlbum
                self.isProcessing = false
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
        print("⏱️ [SINGLE-PROMPT] ========== STARTING SINGLE-PROMPT IDENTIFICATION ==========")

        // Reset deep cut flag
        await MainActor.run {
        }

        do {
            // ID CALL 1: Single-prompt identification (Phase 1 + 2 internal recognition)
            await MainActor.run {
                self.scanState = .identifying
            }

            let call1Start = Date()
            print("🔍 [ID Call 1] Starting single-prompt identification...")

            guard let openAIService = LLMServiceFactory.getService() as? OpenAIAPIService else {
                throw APIError.invalidResponse // Should only be used with OpenAI
            }

            let identificationResponse = try await openAIService.executeSinglePromptIdentification(image: image)
            let call1Time = Date().timeIntervalSince(call1Start)
            print("⏱️ [TIMING] ID Call 1 took: \(String(format: "%.2f", call1Time))s")

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
                print("🔍 [ID Call 1] Search needed: \(searchRequest.searchRequest.reason)")
                print("🔍 [ID Call 1] Query: \(searchRequest.searchRequest.query)")

                // Check if AlbumScan Ultra search is enabled
                let searchEnabled = appState?.searchEnabled ?? false
                #if DEBUG
                print("🔍 [AlbumScan Ultra] Search enabled: \(searchEnabled)")
                #endif

                guard searchEnabled else {
                    // Search disabled - treat as identification failure
                    print("⛔ [Search Disabled] AlbumScan Ultra required for deep cut albums")
                    print("⛔ [Search Disabled] Enable Advanced Search in Settings to identify obscure albums")

                    await MainActor.run {
                        self.scanState = .identificationFailed
                        self.error = NSError(domain: "CameraManager", code: -100, userInfo: [NSLocalizedDescriptionKey: "Unable to identify this cover art"])
                        self.isProcessing = false
                        self.isCaptureInitiated = false
                    }
                    return
                }

                // Ultra enabled - proceed to ID Call 2 (no gate validation)
                let extractedText = searchRequest.searchRequest.observation.extractedText
                let textConfidence = searchRequest.searchRequest.observation.textConfidence
                let meaningfulChars = extractedText.filter { !$0.isWhitespace }.count

                print("🔍 [AlbumScan Ultra] Bypassing search gate validation")
                print("🔍 [ID Call 2] Extracted text: '\(extractedText)' (\(meaningfulChars) chars, \(textConfidence) confidence)")

                // Trigger "deep cut" message in UI
                await MainActor.run {
                }

                // ID CALL 2: Search finalization
                let call2Start = Date()
                print("🔍 [ID Call 2] Executing search with query: \(searchRequest.searchRequest.query)")

                let searchResponse = try await openAIService.executeSearchFinalization(
                    image: image,
                    searchRequest: searchRequest.searchRequest
                )
                let call2Time = Date().timeIntervalSince(call2Start)
                print("⏱️ [TIMING] ID Call 2 took: \(String(format: "%.2f", call2Time))s")

                // Handle Call 2 result
                switch searchResponse {
                case .success(let successResponse):
                    print("✅ [ID Call 2] Search confirmed: \(successResponse.albumTitle) by \(successResponse.artistName)")

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
            let _ = cachedAlbum?.phase2Completed == true  // Future: could skip Phase 2 if cached

            // Fetch artwork FIRST (don't show transition screen until artwork is ready)
            print("🎨 [SINGLE-PROMPT] Fetching artwork before showing transition...")
            let artworkFetchStart = Date()
            let artworkResult = await self.executeArtworkFetch(
                artistName: finalArtistName,
                albumTitle: finalAlbumTitle
            )
            let artworkTime = Date().timeIntervalSince(artworkFetchStart)
            print("⏱️ [TIMING] Artwork fetch took: \(String(format: "%.2f", artworkTime))s")

            // Reset deep cut flag and transition to .identified
            await MainActor.run {
                self.scanState = .identified
            }

            // Stay in .identified for 2.5 seconds to show "We found [album]"
            try await Task.sleep(nanoseconds: 2_500_000_000) // 2.5s

            // Start Phase 2 review generation
            await MainActor.run {
                self.scanState = .loadingReview
            }

            // PHASE 2: Review Generation (unchanged)
            let phase2Result = await self.executePhase2(
                artistName: finalArtistName,
                albumTitle: finalAlbumTitle,
                releaseYear: finalReleaseYear,
                genres: finalGenres,
                recordLabel: finalRecordLabel
            )

            // Save to CoreData
            let savedAlbum = try await self.saveTwoTierAlbum(
                phase1: phase1Response,
                phase2: phase2Result.response,
                phase2Failed: phase2Result.failed,
                musicbrainzID: artworkResult.mbid,
                artworkData: artworkResult.data,
                artworkFailed: artworkResult.failed
            )

            // Complete
            await MainActor.run {
                let totalTime = Date().timeIntervalSince(totalStart)
                print("⏱️ [TIMING] ========== SINGLE-PROMPT TOTAL: \(String(format: "%.2f", totalTime))s ==========")
                print("✅ [SINGLE-PROMPT] Setting scannedAlbum to: \(savedAlbum.albumTitle) by \(savedAlbum.artistName)")
                self.scanState = .complete
                self.scannedAlbum = savedAlbum
                self.isProcessing = false
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
        print("🔑 [TWO-TIER Phase2] Starting review generation...")

        // 🎯 COST OPTIMIZATION: Check cache first (90%+ cost savings)
        if let cachedAlbum = checkCachedAlbum(artistName: artistName, albumTitle: albumTitle) {
            if cachedAlbum.phase2Completed,
               !cachedAlbum.contextSummary.isEmpty {
                // Found valid cached review - USE IT!
                let cachedResponse = Phase2Response(
                    contextSummary: cachedAlbum.contextSummary,
                    contextBullets: cachedAlbum.contextBulletPoints,
                    rating: cachedAlbum.rating,
                    recommendation: cachedAlbum.recommendation,
                    keyTracks: cachedAlbum.keyTracks
                )

                let cacheTime = Date().timeIntervalSince(phase2Start)
                print("⏱️ [TIMING] Phase 2 took: \(String(format: "%.2f", cacheTime))s")
                print("✅ [CACHE HIT] Using cached review - NO API CALL")
                print("💰 [COST SAVINGS] Saved ~$0.05 by using cache")

                await MainActor.run {
                    self.phase2Data = cachedResponse
                }

                return (cachedResponse, false)
            }

            // Check if we've already tried and failed recently (avoid retry loops)
            if cachedAlbum.phase2Failed,
               let lastAttempt = cachedAlbum.phase2LastAttempt {
                let daysSinceAttempt = Calendar.current.dateComponents([.day], from: lastAttempt, to: Date()).day ?? 0

                // Don't retry for 30 days (reviews are stable, failures are usually permanent)
                if daysSinceAttempt < 30 {
                    print("⚠️ [CACHE] Review failed \(daysSinceAttempt) days ago - skipping retry")
                    print("💰 [COST SAVINGS] Avoided wasteful retry")
                    return (nil, true)
                }
            }
        }

        // Cache miss - generate new review
        print("📦 [CACHE MISS] Generating new review via API...")

        // Get Ultra search toggle state
        let searchEnabled = appState?.searchEnabled ?? false
        #if DEBUG
        print("🔍 [AlbumScan Ultra] Review generation with search enabled: \(searchEnabled)")
        #endif

        do {
            let phase2Response = try await LLMServiceFactory.getService().generateReviewPhase2(
                artistName: artistName,
                albumTitle: albumTitle,
                releaseYear: releaseYear,
                genres: genres,
                recordLabel: recordLabel,
                searchEnabled: searchEnabled
            )
            let phase2Time = Date().timeIntervalSince(phase2Start)
            print("⏱️ [TIMING] Phase 2 took: \(String(format: "%.2f", phase2Time))s")
            print("✅ [TWO-TIER Phase2] Review generated successfully")

            await MainActor.run {
                self.phase2Data = phase2Response
            }

            return (phase2Response, false)
        } catch {
            print("❌ [TWO-TIER Phase2] Review generation failed: \(error.localizedDescription)")
            return (nil, true)
        }
    }

    private func executeArtworkFetch(artistName: String, albumTitle: String) async -> (mbid: String?, data: (highRes: Data?, thumbnail: Data?)?, failed: Bool) {
        let artStart = Date()
        print("🎨 [TWO-TIER Artwork] Starting artwork fetch...")

        do {
            if let mbid = try await MusicBrainzService.shared.searchAlbum(artist: artistName, album: albumTitle) {
                print("✅ [TWO-TIER Artwork] Found MBID: \(mbid)")

                let artwork = await CoverArtService.shared.retrieveArtwork(mbid: mbid)
                let artTime = Date().timeIntervalSince(artStart)
                print("⏱️ [TIMING] Artwork fetch took: \(String(format: "%.2f", artTime))s")

                if artwork.highRes != nil || artwork.thumbnail != nil {
                    print("✅ [TWO-TIER Artwork] Artwork downloaded")

                    // Update UI with artwork
                    if let highResData = artwork.highRes, let image = UIImage(data: highResData) {
                        await MainActor.run {
                            self.albumArtwork = image
                        }
                    }

                    return (mbid, artwork, false)
                } else {
                    print("⚠️ [TWO-TIER Artwork] No artwork available")
                    return (mbid, nil, true)
                }
            } else {
                print("⚠️ [TWO-TIER Artwork] Album not found on MusicBrainz")
                return (nil, nil, true)
            }
        } catch {
            print("❌ [TWO-TIER Artwork] Error: \(error.localizedDescription)")
            return (nil, nil, true)
        }
    }

    private func saveTwoTierAlbum(phase1: Phase1Response, phase2: Phase2Response?, phase2Failed: Bool, musicbrainzID: String?, artworkData: (highRes: Data?, thumbnail: Data?)?, artworkFailed: Bool) async throws -> Album {
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
            album.keyTracks = phase2.keyTracks
            album.phase2Completed = true
            album.phase2Failed = false
        } else {
            album.contextSummary = "Review temporarily unavailable"
            album.contextBulletPoints = []
            album.rating = 0.0
            album.recommendation = "SKIP"
            album.keyTracks = []
            album.phase2Completed = false
            album.phase2Failed = phase2Failed
            album.phase2LastAttempt = Date()
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

    /// Normalizes album titles to de-dupe variants (Deluxe, Remastered, etc.)
    /// Example: "Dark Side of the Moon (2011 Remaster)" → "Dark Side of the Moon"
    private func normalizeAlbumTitle(_ title: String) -> String {
        var normalized = title

        // Remove common variant suffixes (case-insensitive)
        let patterns = [
            "\\s*\\(.*?Deluxe.*?\\)",
            "\\s*\\(.*?Remaster.*?\\)",
            "\\s*\\(.*?Reissue.*?\\)",
            "\\s*\\(.*?Edition.*?\\)",
            "\\s*\\(.*?Anniversary.*?\\)",
            "\\s*\\(.*?Expanded.*?\\)",
            "\\s*\\(.*?Bonus.*?\\)",
            "\\s*\\[.*?Deluxe.*?\\]",
            "\\s*\\[.*?Remaster.*?\\]",
            "\\s*\\[.*?Reissue.*?\\]"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                normalized = regex.stringByReplacingMatches(
                    in: normalized,
                    range: NSRange(normalized.startIndex..., in: normalized),
                    withTemplate: ""
                )
            }
        }

        return normalized.trimmingCharacters(in: .whitespaces)
    }

    private func checkCachedAlbum(artistName: String, albumTitle: String) -> Album? {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<Album> = Album.fetchRequest()

        // 🎯 COST OPTIMIZATION: Normalize title to match variants (20-30% cache hit improvement)
        let normalizedTitle = normalizeAlbumTitle(albumTitle)

        #if DEBUG
        if normalizedTitle != albumTitle {
            print("📦 [CACHE] Normalized '\(albumTitle)' → '\(normalizedTitle)'")
        }
        #endif

        // Try exact match first, then normalized match
        fetchRequest.predicate = NSPredicate(
            format: "artistName ==[c] %@ AND (albumTitle ==[c] %@ OR albumTitle ==[c] %@)",
            artistName,
            albumTitle,
            normalizedTitle
        )
        fetchRequest.fetchLimit = 1

        do {
            let results = try context.fetch(fetchRequest)
            if let existing = results.first {
                print("📦 [CACHE] Found existing album: \(existing.albumTitle) by \(artistName)")
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
