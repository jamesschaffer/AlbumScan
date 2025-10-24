import Foundation
import CoreData

@objc(Album)
public class Album: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var albumTitle: String
    @NSManaged public var artistName: String
    @NSManaged public var releaseYear: String?
    @NSManaged public var genresData: Data?
    @NSManaged public var recordLabel: String?

    // Cultural Context
    @NSManaged public var contextSummary: String
    @NSManaged public var contextBulletPointsData: Data?
    @NSManaged public var rating: Double
    @NSManaged public var recommendation: String
    @NSManaged public var keyTracksData: Data?

    // Album Art
    @NSManaged public var albumArtData: Data? // Legacy field - kept for backward compatibility
    @NSManaged public var albumArtURL: String? // Legacy field - kept for backward compatibility

    // Album Art (MusicBrainz + Cover Art Archive)
    @NSManaged public var musicbrainzID: String? // MBID for future reference
    @NSManaged public var albumArtThumbnailData: Data? // Cached 200x200 JPEG for history
    @NSManaged public var albumArtHighResData: Data? // Cached 500px JPEG for detail view
    @NSManaged public var albumArtRetrievalFailed: Bool // Track if artwork lookup failed

    // Metadata
    @NSManaged public var scannedDate: Date
    @NSManaged public var lastViewedDate: Date?

    // Raw API Response (for debugging)
    @NSManaged public var rawAPIResponse: String?

    // Two-Tier API Tracking
    @NSManaged public var phase1Completed: Bool // Track if Phase 1 (identification) succeeded
    @NSManaged public var phase2Completed: Bool // Track if Phase 2 (review) succeeded
    @NSManaged public var phase2Failed: Bool // Track if Phase 2 needs retry
    @NSManaged public var phase2LastAttempt: Date? // When we last tried Phase 2 (for retry logic)
    @NSManaged public var artworkLoaded: Bool // Track if artwork fetch completed

    // Computed properties for array handling
    var genres: [String] {
        get {
            guard let data = genresData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            genresData = try? JSONEncoder().encode(newValue)
        }
    }

    var contextBulletPoints: [String] {
        get {
            guard let data = contextBulletPointsData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            contextBulletPointsData = try? JSONEncoder().encode(newValue)
        }
    }

    var keyTracks: [String] {
        get {
            guard let data = keyTracksData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            keyTracksData = try? JSONEncoder().encode(newValue)
        }
    }

    // Recommendation enum
    enum Recommendation: String {
        case essential = "ESSENTIAL"
        case recommended = "RECOMMENDED"
        case skip = "SKIP"
        case avoid = "AVOID"

        var emoji: String {
            switch self {
            case .essential: return "💎"
            case .recommended: return "👍"
            case .skip: return "😐"
            case .avoid: return "💩"
            }
        }
    }

    var recommendationEnum: Recommendation {
        Recommendation(rawValue: recommendation) ?? .skip
    }
}

extension Album {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Album> {
        return NSFetchRequest<Album>(entityName: "Album")
    }
}
