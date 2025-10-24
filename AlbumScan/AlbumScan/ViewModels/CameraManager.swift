import AVFoundation
import UIKit
import Combine
import CoreData

class CameraManager: NSObject, ObservableObject {
    @Published var isProcessing = false
    @Published var capturedImage: UIImage?
    @Published var error: Error?
    @Published var scannedAlbum: Album?
    @Published var loadingStage: LoadingStage = .callingAPI
    @Published var scanState: ScanState = .idle
    @Published var phase1Data: Phase1Response?
    @Published var phase2Data: Phase2Response?
    @Published var albumArtwork: UIImage?

    // Feature flag: toggle between old single-tier and new two-tier flow
    var useTwoTierFlow = false

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

            // Check if session is running before attempting capture
            guard self.session.isRunning else {
                print("❌ Camera session is not running")
                DispatchQueue.main.async {
                    self.error = NSError(domain: "CameraManager", code: -3, userInfo: [NSLocalizedDescriptionKey: "Camera session is not running. Please restart the app."])
                    self.isProcessing = false
                }
                return
            }

            // Check if photoOutput is connected to the session
            guard self.session.outputs.contains(self.photoOutput) else {
                print("❌ Photo output is not connected to session")
                DispatchQueue.main.async {
                    self.error = NSError(domain: "CameraManager", code: -4, userInfo: [NSLocalizedDescriptionKey: "Camera is not properly configured. Please restart the app."])
                    self.isProcessing = false
                }
                return
            }

            DispatchQueue.main.async {
                self.isProcessing = true
                self.loadingStage = .callingAPI // Reset to first stage
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

            // Send to API (choose flow based on feature flag)
            Task {
                if self.useTwoTierFlow {
                    await self.identifyAlbumTwoTier(image: processedImage)
                } else {
                    await self.identifyAlbum(image: processedImage)
                }
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

        // Resize to 512x512 for API (reduced from 1024 for faster uploads/processing)
        let targetSize = CGSize(width: 512, height: 512)
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
            await MainActor.run {
                self.loadingStage = .callingAPI
            }
            let response = try await ClaudeAPIService.shared.identifyAlbum(image: image)
            let claudeTime = Date().timeIntervalSince(claudeStart)
            print("⏱️ [TIMING] Claude API took: \(String(format: "%.2f", claudeTime))s")
            print("🎵 [CameraManager] API Response received - Album: \(response.albumTitle) by \(response.artistName)")

            // Advance to parsing stage
            await MainActor.run {
                self.loadingStage = .parsingResponse
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
                        self.loadingStage = .downloadingArtwork
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
                        self.loadingStage = .downloadingArtwork
                    }
                }
            } catch {
                print("⚠️ [CameraManager] Artwork retrieval error (non-blocking): \(error.localizedDescription)")
                artworkRetrievalFailed = true

                // Still advance to artwork stage
                await MainActor.run {
                    self.loadingStage = .downloadingArtwork
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

    // MARK: - Two-Tier Flow (New)

    private func identifyAlbumTwoTier(image: UIImage) async {
        let totalStart = Date()
        print("⏱️ [TWO-TIER] ========== STARTING TWO-TIER IDENTIFICATION ==========")

        do {
            // PHASE 1: Fast Identification
            await MainActor.run {
                self.scanState = .identifying
            }

            let phase1Start = Date()
            print("🔑 [TWO-TIER Phase1] Starting fast identification...")
            let phase1Response = try await ClaudeAPIService.shared.identifyAlbumPhase1(image: image)
            let phase1Time = Date().timeIntervalSince(phase1Start)
            print("⏱️ [TIMING] Phase 1 took: \(String(format: "%.2f", phase1Time))s")

            // Check if Phase 1 succeeded
            guard phase1Response.isSuccess,
                  let artistName = phase1Response.artistName,
                  let albumTitle = phase1Response.albumTitle else {
                print("❌ [TWO-TIER Phase1] Identification failed")
                await MainActor.run {
                    self.scanState = .identificationFailed
                    self.error = NSError(domain: "CameraManager", code: -100, userInfo: [NSLocalizedDescriptionKey: phase1Response.displayError])
                    self.isProcessing = false
                }
                return
            }

            print("✅ [TWO-TIER Phase1] Identified: \(albumTitle) by \(artistName)")

            // Store Phase 1 data
            await MainActor.run {
                self.phase1Data = phase1Response
                self.scanState = .identified
            }

            // Brief transition delay (0.5s minimum)
            try await Task.sleep(nanoseconds: 500_000_000)

            // Check cache for existing album with completed Phase 2
            let cachedAlbum = self.checkCachedAlbum(artistName: artistName, albumTitle: albumTitle)
            let shouldSkipPhase2 = cachedAlbum?.phase2Completed == true

            // PHASE 2 & ARTWORK IN PARALLEL
            await MainActor.run {
                self.scanState = .loadingReview
            }

            async let phase2Task: (response: Phase2Response?, failed: Bool) = {
                if shouldSkipPhase2, let cached = cachedAlbum {
                    print("✅ [CACHE] Using cached Phase 2 data, skipping API call")
                    // Build Phase2Response from cached data
                    let cachedResponse = Phase2Response(
                        contextSummary: cached.contextSummary,
                        contextBullets: cached.contextBulletPoints,
                        rating: cached.rating,
                        recommendation: cached.recommendation,
                        keyTracks: cached.keyTracks
                    )
                    await MainActor.run {
                        self.phase2Data = cachedResponse
                    }
                    return (cachedResponse, false)
                } else {
                    // Cache miss or Phase 2 failed previously - call API
                    return await self.executePhase2(
                        artistName: artistName,
                        albumTitle: albumTitle,
                        releaseYear: phase1Response.releaseYear ?? "Unknown",
                        genres: phase1Response.genres ?? [],
                        recordLabel: phase1Response.recordLabel ?? "Unknown"
                    )
                }
            }()

            async let artworkTask = self.executeArtworkFetch(
                artistName: artistName,
                albumTitle: albumTitle
            )

            // Wait for both to complete
            let (phase2Result, artworkResult) = await (phase2Task, artworkTask)

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
                print("⏱️ [TIMING] ========== TWO-TIER TOTAL: \(String(format: "%.2f", totalTime))s ==========")
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

    private func executePhase2(artistName: String, albumTitle: String, releaseYear: String, genres: [String], recordLabel: String) async -> (response: Phase2Response?, failed: Bool) {
        let phase2Start = Date()
        print("🔑 [TWO-TIER Phase2] Starting review generation...")

        do {
            let phase2Response = try await ClaudeAPIService.shared.generateReviewPhase2(
                artistName: artistName,
                albumTitle: albumTitle,
                releaseYear: releaseYear,
                genres: genres,
                recordLabel: recordLabel
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
