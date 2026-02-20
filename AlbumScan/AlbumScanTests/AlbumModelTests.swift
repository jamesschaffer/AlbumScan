import Testing
import CoreData
@testable import AlbumScan

@Suite("Album Model Tests")
struct AlbumModelTests {

    // MARK: - Helpers

    private func makeAlbum() -> (Album, NSManagedObjectContext) {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let album = Album(context: context)
        album.id = UUID()
        album.albumTitle = "OK Computer"
        album.artistName = "Radiohead"
        album.releaseYear = "1997"
        album.contextSummary = "A landmark album"
        album.rating = 9.2
        album.recommendation = "ESSENTIAL"
        album.scannedDate = Date()
        album.phase1Completed = true
        album.phase2Completed = false
        return (album, context)
    }

    // MARK: - Recommendation enum

    @Test func recommendationRawValues() {
        #expect(Album.Recommendation.essential.rawValue == "ESSENTIAL")
        #expect(Album.Recommendation.recommended.rawValue == "RECOMMENDED")
        #expect(Album.Recommendation.skip.rawValue == "SKIP")
        #expect(Album.Recommendation.avoid.rawValue == "AVOID")
    }

    @Test func recommendationEmojis() {
        #expect(Album.Recommendation.essential.emoji == "💎")
        #expect(Album.Recommendation.recommended.emoji == "👍")
        #expect(Album.Recommendation.skip.emoji == "😐")
        #expect(Album.Recommendation.avoid.emoji == "💩")
    }

    // MARK: - JSON array properties

    @Test func genresRoundTrip() {
        let (album, _) = makeAlbum()
        let genres = ["Alternative Rock", "Art Rock", "Electronic"]
        album.genres = genres
        #expect(album.genres == genres)
    }

    @Test func contextBulletPointsRoundTrip() {
        let (album, _) = makeAlbum()
        let bullets = ["Critically acclaimed", "Sold 10M copies"]
        album.contextBulletPoints = bullets
        #expect(album.contextBulletPoints == bullets)
    }

    @Test func keyTracksRoundTrip() {
        let (album, _) = makeAlbum()
        let tracks = ["Paranoid Android", "Karma Police", "No Surprises"]
        album.keyTracks = tracks
        #expect(album.keyTracks == tracks)
    }

    // MARK: - toPhase2Response

    @Test func toPhase2ResponseReturnsNilWhenNotCompleted() {
        let (album, _) = makeAlbum()
        album.phase2Completed = false
        #expect(album.toPhase2Response() == nil)
    }

    @Test func toPhase2ResponseReturnsValueWhenCompleted() {
        let (album, _) = makeAlbum()
        album.phase2Completed = true
        album.contextSummary = "A landmark album"
        album.contextBulletPoints = ["Point 1"]
        album.rating = 9.2
        album.recommendation = "ESSENTIAL"
        album.keyTracks = ["Paranoid Android"]

        let response = album.toPhase2Response()
        #expect(response != nil)
        #expect(response?.contextSummary == "A landmark album")
        #expect(response?.rating == 9.2)
        #expect(response?.recommendation == "ESSENTIAL")
    }
}
