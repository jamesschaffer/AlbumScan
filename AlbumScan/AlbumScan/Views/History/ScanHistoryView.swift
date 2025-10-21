import SwiftUI
import CoreData

struct ScanHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Album.scannedDate, ascending: false)],
        animation: .default)
    private var albums: FetchedResults<Album>

    var body: some View {
        NavigationView {
            VStack {
                if albums.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "clock")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        Text("Scan your first album to begin")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    // Album list
                    List {
                        ForEach(albums) { album in
                            AlbumHistoryRow(album: album)
                        }
                        .onDelete(perform: deleteAlbums)
                    }
                }

                // Scan button at bottom
                Button(action: {
                    dismiss()
                }) {
                    Text("SCAN")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Scan History")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func deleteAlbums(offsets: IndexSet) {
        withAnimation {
            offsets.map { albums[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                print("Error deleting album: \(error)")
            }
        }
    }
}

struct AlbumHistoryRow: View {
    let album: Album
    @State private var showingDetails = false

    var body: some View {
        Button(action: {
            showingDetails = true
        }) {
            HStack(spacing: 12) {
                // Thumbnail (prefer thumbnail data from MusicBrainz, fallback to legacy)
                if let thumbnailData = album.albumArtThumbnailData,
                   let uiImage = UIImage(data: thumbnailData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .cornerRadius(6)
                        .clipped()
                } else if let legacyArtData = album.albumArtData,
                          let uiImage = UIImage(data: legacyArtData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .cornerRadius(6)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .cornerRadius(6)
                }

                // Album info
                VStack(alignment: .leading, spacing: 4) {
                    Text(album.albumTitle)
                        .font(.headline)
                        .lineLimit(1)

                    Text(album.artistName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text(album.recommendationEnum.emoji)
                            .font(.caption)
                        Text("\(album.recommendation) / \(album.rating, specifier: "%.1f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
        }
        .sheet(isPresented: $showingDetails) {
            AlbumDetailsView(album: album)
        }
    }
}

struct ScanHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ScanHistoryView()
    }
}
