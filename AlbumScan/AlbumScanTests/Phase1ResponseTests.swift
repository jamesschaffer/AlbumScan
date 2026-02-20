import Testing
@testable import AlbumScan

@Suite("Phase1Response Tests")
struct Phase1ResponseTests {

    @Test func isSuccessWhenAllFieldsPresent() {
        let response = Phase1Response(
            success: true,
            artistName: "Radiohead",
            albumTitle: "OK Computer",
            releaseYear: "1997",
            genres: ["Alternative Rock"],
            recordLabel: "Parlophone",
            errorMessage: nil
        )
        #expect(response.isSuccess == true)
    }

    @Test func isNotSuccessWhenSuccessFalse() {
        let response = Phase1Response(
            success: false,
            artistName: "Radiohead",
            albumTitle: "OK Computer",
            releaseYear: nil,
            genres: nil,
            recordLabel: nil,
            errorMessage: "Could not identify"
        )
        #expect(response.isSuccess == false)
    }

    @Test func isNotSuccessWhenArtistNameNil() {
        let response = Phase1Response(
            success: true,
            artistName: nil,
            albumTitle: "OK Computer",
            releaseYear: nil,
            genres: nil,
            recordLabel: nil,
            errorMessage: nil
        )
        #expect(response.isSuccess == false)
    }

    @Test func isNotSuccessWhenAlbumTitleNil() {
        let response = Phase1Response(
            success: true,
            artistName: "Radiohead",
            albumTitle: nil,
            releaseYear: nil,
            genres: nil,
            recordLabel: nil,
            errorMessage: nil
        )
        #expect(response.isSuccess == false)
    }

    @Test func displayErrorReturnsErrorMessage() {
        let response = Phase1Response(
            success: false,
            artistName: nil,
            albumTitle: nil,
            releaseYear: nil,
            genres: nil,
            recordLabel: nil,
            errorMessage: "Image too blurry"
        )
        #expect(response.displayError == "Image too blurry")
    }

    @Test func displayErrorReturnsFallbackWhenNil() {
        let response = Phase1Response(
            success: false,
            artistName: nil,
            albumTitle: nil,
            releaseYear: nil,
            genres: nil,
            recordLabel: nil,
            errorMessage: nil
        )
        #expect(response.displayError == "Could not identify album cover")
    }
}
