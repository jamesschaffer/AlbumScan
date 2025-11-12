import SwiftUI

struct AlbumDetailsView: View {
    let album: Album
    @Environment(\.dismiss) var dismiss
    @State private var showingHistory = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Album artwork with recommendation badge overlay
                    ZStack(alignment: .bottomTrailing) {
                        // Album artwork (prefer high-res from MusicBrainz, fallback to legacy)
                        if let artData = album.albumArtHighResData,
                           let uiImage = UIImage(data: artData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .cornerRadius(8)
                        } else if let legacyArtData = album.albumArtData,
                                  let uiImage = UIImage(data: legacyArtData) {
                            // Fallback to legacy artwork field
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

                        // Recommendation Badge - positioned in bottom-right corner
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
                        .padding([.trailing, .bottom], 6)
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
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                            Text("History")
                                .font(.body)
                        }
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
            return Color(red: 0.56, green: 0.93, blue: 0.56) // Light green
        case "RECOMMENDED":
            return Color(red: 0.68, green: 0.85, blue: 0.90) // Light blue
        case "SKIP":
            return Color(red: 1.0, green: 0.87, blue: 0.68) // Light orange
        case "AVOID":
            return Color(red: 1.0, green: 0.76, blue: 0.76) // Light red
        default:
            return Color(red: 0.85, green: 0.85, blue: 0.85) // Light gray
        }
    }
}
