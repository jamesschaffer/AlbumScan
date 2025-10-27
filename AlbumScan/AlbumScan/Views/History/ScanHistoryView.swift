import SwiftUI
import CoreData

struct ScanHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Album.scannedDate, ascending: false)],
        animation: .default)
    private var albums: FetchedResults<Album>

    let brandGreen = Color(red: 0, green: 0.87, blue: 0.32)

    var body: some View {
        ZStack {
            // Black background
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Add top padding for the logo
                Color.clear.frame(height: 60)
                if albums.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "clock")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.6))

                        Text("Scan your first album to begin")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                    }
                } else {
                    // Album list - extends to bottom edge, scrolls behind button
                    List {
                        ForEach(albums) { album in
                            AlbumHistoryRow(album: album)
                                .listRowBackground(Color.black)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteAlbum(album)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .tint(.red)
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(.black)
                    .safeAreaInset(edge: .bottom) {
                        // Spacer to allow scrolling past button
                        Color.clear.frame(height: 120)
                    }
                }
            }

            // Camera button overlaid at bottom right
            VStack {
                Spacer()

                HStack {
                    Spacer()

                    Button(action: {
                        dismiss()
                    }) {
                        HStack(alignment: .center, spacing: 0) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 64, height: 64)
                        .background(.black.opacity(0.6))
                        .cornerRadius(999)
                        .overlay(
                            RoundedRectangle(cornerRadius: 999)
                                .inset(by: 2)
                                .stroke(brandGreen, lineWidth: 4)
                        )
                    }
                    .buttonStyle(PressedButtonStyle())
                    .padding(.trailing, 20)
                    .padding(.bottom, 22)
                }
            }

            // Logo container fixed at top with black semi-transparent background
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Image("album-scan-logo-simple-white")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 185)
                    Spacer()
                }
                .frame(height: 60)
                .background(.black.opacity(0.8))

                Spacer()
            }
        }
    }

    private func deleteAlbums(offsets: IndexSet) {
        withAnimation {
            offsets.map { albums[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                #if DEBUG
                print("Error deleting album: \(error)")
                #endif
            }
        }
    }

    private func deleteAlbum(_ album: Album) {
        withAnimation {
            viewContext.delete(album)

            do {
                try viewContext.save()
            } catch {
                #if DEBUG
                print("Error deleting album: \(error)")
                #endif
            }
        }
    }
}

struct AlbumHistoryRow: View {
    let album: Album
    @State private var showingDetails = false

    // MARK: - Typography Settings (Adjust these values to customize fonts)

    // Album Title Settings
    private let albumTitleFontSize: CGFloat = 20
    private let albumTitleLineHeight: CGFloat = 6
    private let albumTitleFontWeight: Font.Weight = .semibold
    private let albumTitleColor: Color = .white

    // Artist Name (Band Name) Settings
    private let artistNameFontSize: CGFloat = 18
    private let artistNameLineHeight: CGFloat = 6
    private let artistNameFontWeight: Font.Weight = .regular
    private let artistNameColor: Color = .white

    // Recommendation Text Settings (e.g., "ESSENTIAL / ")
    private let recommendationFontSize: CGFloat = 14
    private let recommendationLineHeight: CGFloat = 6
    private let recommendationFontWeight: Font.Weight = .regular
    private let recommendationColor: Color = .white

    // Score Text Settings (e.g., "9.5")
    private let scoreFontSize: CGFloat = 14
    private let scoreLineHeight: CGFloat = 4
    private let scoreFontWeight: Font.Weight = .bold
    private let scoreColor: Color = Color(red: 0, green: 0.87, blue: 0.32)  // Brand green

    // Brand Colors
    let brandGreen = Color(red: 0, green: 0.87, blue: 0.32)

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
                        .frame(width: 96, height: 96)
                        .cornerRadius(6)
                        .clipped()
                } else if let legacyArtData = album.albumArtData,
                          let uiImage = UIImage(data: legacyArtData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 96, height: 96)
                        .cornerRadius(6)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 96, height: 96)
                        .cornerRadius(6)
                }

                // Album info
                VStack(alignment: .leading, spacing: 4) {
                    Text(album.albumTitle)
                        .font(.system(size: albumTitleFontSize, weight: albumTitleFontWeight))
                        .lineSpacing(albumTitleLineHeight)
                        .foregroundColor(albumTitleColor)
                        .lineLimit(1)

                    Text(album.artistName)
                        .font(.system(size: artistNameFontSize, weight: artistNameFontWeight))
                        .lineSpacing(artistNameLineHeight)
                        .foregroundColor(artistNameColor.opacity(0.8))
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text(album.recommendationEnum.emoji)
                            .font(.system(size: recommendationFontSize, weight: recommendationFontWeight))
                            .lineSpacing(recommendationLineHeight)
                        Text("\(album.recommendation) / ")
                            .font(.system(size: recommendationFontSize, weight: recommendationFontWeight))
                            .lineSpacing(recommendationLineHeight)
                            .foregroundColor(recommendationColor.opacity(0.8))
                        Text("\(album.rating, specifier: "%.1f")")
                            .font(.system(size: scoreFontSize, weight: scoreFontWeight))
                            .lineSpacing(scoreLineHeight)
                            .foregroundColor(scoreColor)
                    }
                }

                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showingDetails) {
            AlbumDetailsView(album: album)
        }
    }
}

struct ScanHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ScanHistoryView()
    }
}
