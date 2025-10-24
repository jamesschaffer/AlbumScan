import SwiftUI

struct AlbumDetailsView: View {
    let album: Album
    @Environment(\.dismiss) var dismiss

    // MARK: - Typography Settings (Adjust these values to customize fonts)

    // Band Name (Artist Name) Settings
    private let bandNameFontSize: CGFloat = 26
    private let bandNameLineHeight: CGFloat = 18
    private let bandNameColor: Color = .primary

    // Album Title Settings
    private let albumTitleFontSize: CGFloat = 22
    private let albumTitleLineHeight: CGFloat = 18
    private let albumTitleColor: Color = .primary

    // Body Text Settings
    private let bodyTextFontSize: CGFloat = 18
    private let bodyTextLineHeight: CGFloat = 8
    private let bodyTextColor: Color = .primary

    // Metadata Settings (Release Year, Genre, Label)
    private let metadataFontSize: CGFloat = 18
    private let metadataLineHeight: CGFloat = 6
    private let metadataLabelColor: Color = Color(red: 0.2, green: 0.2, blue: 0.2)  // 80% black for bold labels
    private let metadataValueColor: Color = .secondary  // Light gray for values

    // List Indentation Settings
    private let listItemIndent: CGFloat = 8  // Indent for bullet points and list items

    // Brand Colors
    let brandGreen = Color(red: 0, green: 0.87, blue: 0.32)

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Add top padding for the logo
                    Color.clear.frame(height: 50)
                    // Album artwork with recommendation badge overlay
                    ZStack(alignment: .bottomTrailing) {
                        // Album artwork (prefer high-res from MusicBrainz, fallback to legacy)
                        if let artData = album.albumArtHighResData,
                           let uiImage = UIImage(data: artData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(1, contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .cornerRadius(8)
                        } else if let legacyArtData = album.albumArtData,
                                  let uiImage = UIImage(data: legacyArtData) {
                            // Fallback to legacy artwork field
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(1, contentMode: .fit)
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
                            Text("\(album.recommendation) / \(album.rating, specifier: "%.1f")")
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
                            .font(
                                Font.custom("Helvetica Neue", size: bandNameFontSize)
                                    .weight(.bold)
                            )
                            .lineSpacing(bandNameLineHeight)
                            .foregroundColor(bandNameColor)
                            .lineLimit(1)

                        Text(album.albumTitle)
                            .font(
                                Font.custom("Helvetica Neue", size: albumTitleFontSize)
                                    .weight(.bold)
                            )
                            .lineSpacing(albumTitleLineHeight)
                            .foregroundColor(albumTitleColor)
                            .lineLimit(1)
                    }
                    .padding(.top, 4)

                    // Metadata (Release Year, Genre, Label)
                    VStack(alignment: .leading, spacing: 4) {
                        if let year = album.releaseYear {
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text("Released:")
                                    .font(Font.custom("Helvetica Neue", size: metadataFontSize).weight(.bold))
                                    .foregroundColor(metadataLabelColor)
                                    .frame(width: 95, alignment: .leading)
                                Text("\(year)")
                                    .font(Font.custom("Helvetica Neue", size: metadataFontSize))
                                    .lineSpacing(metadataLineHeight - 2)
                                    .foregroundColor(metadataValueColor)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.vertical, 2)
                        }

                        if !album.genres.isEmpty {
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text("Genre:")
                                    .font(Font.custom("Helvetica Neue", size: metadataFontSize).weight(.bold))
                                    .foregroundColor(metadataLabelColor)
                                    .frame(width: 95, alignment: .leading)
                                Text("\(album.genres.joined(separator: ", "))")
                                    .font(Font.custom("Helvetica Neue", size: metadataFontSize))
                                    .lineSpacing(metadataLineHeight - 2)
                                    .foregroundColor(metadataValueColor)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.vertical, 2)
                        }

                        if let label = album.recordLabel {
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text("Label:")
                                    .font(Font.custom("Helvetica Neue", size: metadataFontSize).weight(.bold))
                                    .foregroundColor(metadataLabelColor)
                                    .frame(width: 95, alignment: .leading)
                                Text("\(label)")
                                    .font(Font.custom("Helvetica Neue", size: metadataFontSize))
                                    .lineSpacing(metadataLineHeight - 2)
                                    .foregroundColor(metadataValueColor)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    // Cultural Context Summary
                    Text(album.contextSummary)
                        .font(Font.custom("Helvetica Neue", size: bodyTextFontSize))
                        .lineSpacing(bodyTextLineHeight)
                        .foregroundColor(bodyTextColor)
                        .padding(.vertical, 8)

                    // Bullet Points
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(album.contextBulletPoints, id: \.self) { bullet in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .font(Font.custom("Helvetica Neue", size: bodyTextFontSize))
                                    .foregroundColor(bodyTextColor)
                                Text(bullet)
                                    .font(Font.custom("Helvetica Neue", size: bodyTextFontSize))
                                    .lineSpacing(bodyTextLineHeight)
                                    .foregroundColor(bodyTextColor)
                            }
                            .padding(.leading, listItemIndent)
                        }
                    }

                    // Rating
                    HStack {
                        Text("Rating:")
                            .font(
                                Font.custom("Helvetica Neue", size: albumTitleFontSize)
                                    .weight(.bold)
                            )
                            .foregroundColor(albumTitleColor)
                        Text("\(album.rating, specifier: "%.1f")/10")
                            .font(
                                Font.custom("Helvetica Neue", size: albumTitleFontSize)
                                    .weight(.bold)
                            )
                            .foregroundColor(albumTitleColor)
                    }
                    .padding(.top, 8)

                    // Key Tracks
                    if !album.keyTracks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("🎵 Key Tracks")
                                .font(
                                    Font.custom("Helvetica Neue", size: albumTitleFontSize)
                                        .weight(.bold)
                                )
                                .foregroundColor(albumTitleColor)

                            ForEach(album.keyTracks, id: \.self) { track in
                                Text("• \(track)")
                                    .font(Font.custom("Helvetica Neue", size: bodyTextFontSize))
                                    .lineSpacing(bodyTextLineHeight)
                                    .foregroundColor(bodyTextColor)
                                    .padding(.leading, listItemIndent)
                            }
                        }
                        .padding(.top, 8)
                    }

                    Spacer(minLength: 40)

                    // AI Disclaimer - at very bottom
                    Text("These ratings are generated fresh each time and may vary wildly, much like asking three different music snobs about the same album—it's all vibes, baby.")
                        .font(Font.custom("Helvetica Neue", size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
                .padding()
                .padding(.bottom, 100) // Add padding for the close button
            }

            // Logo container fixed at top with white semi-transparent background
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Image("album-scan-logo-simple-black")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 185)
                    Spacer()
                }
                .frame(height: 60)
                .background(.white.opacity(0.6))

                Spacer()
            }

            // Close button styled like camera view's History button
            VStack {
                Spacer()

                HStack {
                    Spacer()

                    Button(action: {
                        dismiss()
                    }) {
                        HStack(alignment: .center, spacing: 0) {
                            Image(systemName: "xmark")
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
        }
        .preferredColorScheme(.light)
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
