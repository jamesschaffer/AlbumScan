import Foundation

struct AlbumResponse: Codable {
    let albumTitle: String
    let artistName: String
    let releaseYear: String?
    let genres: [String]
    let recordLabel: String?
    let contextSummary: String
    let contextBullets: [String]
    let rating: Double
    let recommendation: String
    let keyTracks: [String]
    let albumArtURL: String?

    enum CodingKeys: String, CodingKey {
        case albumTitle = "album_title"
        case artistName = "artist_name"
        case releaseYear = "release_year"
        case genres
        case recordLabel = "record_label"
        case contextSummary = "context_summary"
        case contextBullets = "context_bullets"
        case rating
        case recommendation
        case keyTracks = "key_tracks"
        case albumArtURL = "album_art_url"
    }
}
