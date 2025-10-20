import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "AlbumScan")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func saveAlbum(from response: AlbumResponse, musicbrainzID: String?, artworkData: (highRes: Data?, thumbnail: Data?)?, artworkRetrievalFailed: Bool) throws -> Album {
        let context = container.viewContext

        let album = Album(context: context)
        album.id = UUID()
        album.albumTitle = response.albumTitle
        album.artistName = response.artistName
        album.releaseYear = response.releaseYear
        album.genres = response.genres
        album.recordLabel = response.recordLabel
        album.contextSummary = response.contextSummary
        album.contextBulletPoints = response.contextBullets
        album.rating = response.rating
        album.recommendation = response.recommendation
        album.keyTracks = response.keyTracks

        // Legacy fields (kept for backward compatibility)
        album.albumArtURL = response.albumArtURL
        album.albumArtData = nil

        // New MusicBrainz + Cover Art Archive fields
        album.musicbrainzID = musicbrainzID
        album.albumArtHighResData = artworkData?.highRes
        album.albumArtThumbnailData = artworkData?.thumbnail
        album.albumArtRetrievalFailed = artworkRetrievalFailed

        album.scannedDate = Date()

        try context.save()
        return album
    }

    func deleteAlbum(_ album: Album) throws {
        let context = container.viewContext
        context.delete(album)
        try context.save()
    }

    func fetchAllAlbums() -> [Album] {
        let request: NSFetchRequest<Album> = Album.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Album.scannedDate, ascending: false)]

        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("Error fetching albums: \(error)")
            return []
        }
    }
}
