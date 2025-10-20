import SwiftUI

struct AlbumDetailsView: View {
    let album: Album
    @Environment(\.dismiss) var dismiss
    @State private var showingHistory = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Album artwork
                    if let artData = album.albumArtData,
                       let uiImage = UIImage(data: artData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(8)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                Text("Album art unavailable")
                                    .foregroundColor(.secondary)
                            )
                            .cornerRadius(8)
                    }

                    // Artist and Album Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text(album.artistName)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(album.albumTitle)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }

                    // Recommendation Badge
                    HStack {
                        Text(album.recommendationEnum.emoji)
                            .font(.title)
                        Text(album.recommendation)
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(recommendationColor(for: album.recommendation))
                    .cornerRadius(8)

                    // Cultural Context Summary
                    Text(album.contextSummary)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.vertical, 8)

                    // Bullet Points
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(album.contextBulletPoints, id: \.self) { bullet in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .font(.body)
                                Text(bullet)
                                    .font(.body)
                            }
                        }
                    }

                    // Rating
                    HStack {
                        Text("Rating:")
                            .font(.headline)
                        Text("\(album.rating, specifier: "%.1f")/10")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 8)

                    // Key Tracks
                    if !album.keyTracks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Key Tracks")
                                .font(.headline)

                            ForEach(album.keyTracks, id: \.self) { track in
                                Text("• \(track)")
                                    .font(.body)
                            }
                        }
                        .padding(.top, 8)
                    }

                    // Metadata
                    VStack(alignment: .leading, spacing: 4) {
                        if let year = album.releaseYear {
                            Text("Released: \(year)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        if !album.genres.isEmpty {
                            Text("Genre: \(album.genres.joined(separator: ", "))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        if let label = album.recordLabel {
                            Text("Label: \(label)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingHistory = true
                    }) {
                        Image(systemName: "clock")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingHistory) {
            ScanHistoryView()
        }
    }

    private func recommendationColor(for recommendation: String) -> Color {
        switch recommendation {
        case "ESSENTIAL":
            return Color.green.opacity(0.2)
        case "RECOMMENDED":
            return Color.blue.opacity(0.2)
        case "SKIP":
            return Color.orange.opacity(0.2)
        case "AVOID":
            return Color.red.opacity(0.2)
        default:
            return Color.gray.opacity(0.2)
        }
    }
}
