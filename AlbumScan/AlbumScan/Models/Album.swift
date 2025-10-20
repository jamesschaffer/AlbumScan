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
    @NSManaged public var albumArtData: Data?
    @NSManaged public var albumArtURL: String?

    // Metadata
    @NSManaged public var scannedDate: Date
    @NSManaged public var lastViewedDate: Date?

    // Raw API Response (for debugging)
    @NSManaged public var rawAPIResponse: String?

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
