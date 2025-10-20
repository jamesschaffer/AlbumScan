import SwiftUI
import CoreData

struct ScanHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @State private var showingCamera = false

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
                    showingCamera = true
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "clock")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView()
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
                // Thumbnail
                if let artData = album.albumArtData,
                   let uiImage = UIImage(data: artData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .cornerRadius(6)
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

                    Text(album.scannedDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
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
