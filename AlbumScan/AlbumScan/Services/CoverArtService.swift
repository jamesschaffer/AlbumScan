import Foundation
import UIKit

// MARK: - Cover Art Archive Response Models

struct CoverArtArchiveResponse: Codable {
    let images: [CoverArtImage]
}

struct CoverArtImage: Codable {
    let types: [String]
    let front: Bool
    let image: String // Original full-size URL
    let thumbnails: CoverArtThumbnails
}

struct CoverArtThumbnails: Codable {
    let small: String  // 250px
    let large: String  // 500px
}

// MARK: - Cover Art Service

class CoverArtService {
    static let shared = CoverArtService()

    private let baseURL = "https://coverartarchive.org/release"

    private init() {}

    /// Retrieve album artwork URLs from Cover Art Archive
    func getArtworkURLs(mbid: String) async throws -> (largeURL: String, thumbnailURL: String)? {
        print("🎨 [CoverArt] Fetching artwork for MBID: \(mbid)")

        guard let url = URL(string: "\(baseURL)/\(mbid)") else {
            throw CoverArtError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5.0

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw CoverArtError.invalidResponse
            }

            print("🎨 [CoverArt] Response status: \(httpResponse.statusCode)")

            // 404 is common for obscure releases
            if httpResponse.statusCode == 404 {
                print("⚠️ [CoverArt] No artwork found (404)")
                return nil
            }

            guard httpResponse.statusCode == 200 else {
                throw CoverArtError.httpError(httpResponse.statusCode)
            }

            let coverArtResponse = try JSONDecoder().decode(CoverArtArchiveResponse.self, from: data)

            // Find the front cover image
            let frontImage = coverArtResponse.images.first { $0.front && $0.types.contains("Front") }
                ?? coverArtResponse.images.first { $0.front }
                ?? coverArtResponse.images.first

            guard let artwork = frontImage else {
                print("⚠️ [CoverArt] No images in response")
                return nil
            }

            print("✅ [CoverArt] Found artwork URLs")
            return (largeURL: artwork.thumbnails.large, thumbnailURL: artwork.thumbnails.small)

        } catch {
            // Don't throw on network errors - just return nil so app can show placeholder
            print("⚠️ [CoverArt] Error fetching artwork: \(error.localizedDescription)")
            return nil
        }
    }

    /// Download and process artwork images
    func downloadArtwork(largeURL: String, thumbnailURL: String) async throws -> (highRes: Data, thumbnail: Data) {
        print("📥 [CoverArt] Downloading images...")

        // Convert HTTP to HTTPS (Cover Art Archive supports both)
        let securelargeURL = largeURL.replacingOccurrences(of: "http://", with: "https://")
        let secureThumbnailURL = thumbnailURL.replacingOccurrences(of: "http://", with: "https://")

        // Download large (500px) image for detail view
        guard let largeImageURL = URL(string: securelargeURL) else {
            throw CoverArtError.invalidURL
        }

        let (largeData, largeResponse) = try await URLSession.shared.data(from: largeImageURL)

        guard let httpResponse = largeResponse as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw CoverArtError.downloadFailed
        }

        // Download small (250px) image - we'll resize to 200x200 for thumbnail
        guard let thumbnailImageURL = URL(string: secureThumbnailURL) else {
            throw CoverArtError.invalidURL
        }

        let (thumbnailData, thumbnailResponse) = try await URLSession.shared.data(from: thumbnailImageURL)

        guard let thumbnailHttpResponse = thumbnailResponse as? HTTPURLResponse,
              thumbnailHttpResponse.statusCode == 200 else {
            throw CoverArtError.downloadFailed
        }

        // Resize thumbnail to 200x200 for consistency
        guard let thumbnailImage = UIImage(data: thumbnailData),
              let resizedThumbnail = resizeImage(thumbnailImage, targetSize: CGSize(width: 200, height: 200)),
              let resizedThumbnailData = resizedThumbnail.jpegData(compressionQuality: 0.8) else {
            throw CoverArtError.imageProcessingFailed
        }

        print("✅ [CoverArt] Images downloaded and processed")
        return (highRes: largeData, thumbnail: resizedThumbnailData)
    }

    /// Complete artwork retrieval flow: Get URLs → Download → Process
    func retrieveArtwork(mbid: String) async -> (highRes: Data?, thumbnail: Data?) {
        do {
            // Step 1: Get artwork URLs
            guard let urls = try await getArtworkURLs(mbid: mbid) else {
                print("⚠️ [CoverArt] No artwork available")
                return (nil, nil)
            }

            // Step 2: Download images
            let (highRes, thumbnail) = try await downloadArtwork(largeURL: urls.largeURL, thumbnailURL: urls.thumbnailURL)
            return (highRes, thumbnail)

        } catch {
            print("❌ [CoverArt] Artwork retrieval failed: \(error.localizedDescription)")
            return (nil, nil)
        }
    }

    /// Resize image to target size (maintains aspect ratio, centers and crops)
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // Use larger ratio to fill the target size
        let scaleFactor = max(widthRatio, heightRatio)

        let scaledWidth  = size.width * scaleFactor
        let scaledHeight = size.height * scaleFactor

        let originX = (targetSize.width - scaledWidth) / 2
        let originY = (targetSize.height - scaledHeight) / 2

        let targetRect = CGRect(x: originX, y: originY, width: scaledWidth, height: scaledHeight)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { context in
            image.draw(in: targetRect)
        }

        return resizedImage
    }
}

// MARK: - Errors

enum CoverArtError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case downloadFailed
    case imageProcessingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Cover Art Archive URL"
        case .invalidResponse:
            return "Invalid response from Cover Art Archive"
        case .httpError(let code):
            return "Cover Art Archive HTTP error: \(code)"
        case .downloadFailed:
            return "Failed to download artwork"
        case .imageProcessingFailed:
            return "Failed to process artwork image"
        }
    }
}
