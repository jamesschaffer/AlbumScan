import Testing
@testable import AlbumScan

@Suite("Phase2Response Tests")
struct Phase2ResponseTests {

    private func validResponse() -> Phase2Response {
        Phase2Response(
            contextSummary: "A landmark album of the 1990s",
            contextBullets: ["Critically acclaimed", "Sold 10M copies"],
            rating: 9.2,
            recommendation: "ESSENTIAL",
            keyTracks: ["Paranoid Android", "Karma Police"]
        )
    }

    // MARK: - isValid

    @Test func isValidWithCompleteResponse() {
        #expect(validResponse().isValid == true)
    }

    @Test func isNotValidWithEmptyContextSummary() {
        let response = Phase2Response(
            contextSummary: "",
            contextBullets: ["Point 1"],
            rating: 8.0,
            recommendation: "RECOMMENDED",
            keyTracks: ["Track 1"]
        )
        #expect(response.isValid == false)
    }

    @Test func isNotValidWithEmptyContextBullets() {
        let response = Phase2Response(
            contextSummary: "Summary",
            contextBullets: [],
            rating: 8.0,
            recommendation: "RECOMMENDED",
            keyTracks: ["Track 1"]
        )
        #expect(response.isValid == false)
    }

    @Test func isNotValidWithNegativeRating() {
        let response = Phase2Response(
            contextSummary: "Summary",
            contextBullets: ["Point 1"],
            rating: -1.0,
            recommendation: "SKIP",
            keyTracks: ["Track 1"]
        )
        #expect(response.isValid == false)
    }

    @Test func isNotValidWithRatingAboveTen() {
        let response = Phase2Response(
            contextSummary: "Summary",
            contextBullets: ["Point 1"],
            rating: 10.5,
            recommendation: "ESSENTIAL",
            keyTracks: ["Track 1"]
        )
        #expect(response.isValid == false)
    }

    @Test func isNotValidWithEmptyRecommendation() {
        let response = Phase2Response(
            contextSummary: "Summary",
            contextBullets: ["Point 1"],
            rating: 7.0,
            recommendation: "",
            keyTracks: ["Track 1"]
        )
        #expect(response.isValid == false)
    }

    @Test func isNotValidWithEmptyKeyTracks() {
        let response = Phase2Response(
            contextSummary: "Summary",
            contextBullets: ["Point 1"],
            rating: 7.0,
            recommendation: "RECOMMENDED",
            keyTracks: []
        )
        #expect(response.isValid == false)
    }

    // MARK: - recommendationEmoji

    @Test func essentialEmoji() {
        let response = Phase2Response(
            contextSummary: "S", contextBullets: ["B"], rating: 9.5,
            recommendation: "ESSENTIAL", keyTracks: ["T"]
        )
        #expect(response.recommendationEmoji == "💎")
    }

    @Test func recommendedEmoji() {
        let response = Phase2Response(
            contextSummary: "S", contextBullets: ["B"], rating: 7.0,
            recommendation: "RECOMMENDED", keyTracks: ["T"]
        )
        #expect(response.recommendationEmoji == "👍")
    }

    @Test func skipEmoji() {
        let response = Phase2Response(
            contextSummary: "S", contextBullets: ["B"], rating: 4.0,
            recommendation: "SKIP", keyTracks: ["T"]
        )
        #expect(response.recommendationEmoji == "😐")
    }

    @Test func avoidEmoji() {
        let response = Phase2Response(
            contextSummary: "S", contextBullets: ["B"], rating: 2.0,
            recommendation: "AVOID", keyTracks: ["T"]
        )
        #expect(response.recommendationEmoji == "💩")
    }

    @Test func unknownRecommendationEmoji() {
        let response = Phase2Response(
            contextSummary: "S", contextBullets: ["B"], rating: 5.0,
            recommendation: "UNKNOWN", keyTracks: ["T"]
        )
        #expect(response.recommendationEmoji == "❓")
    }
}
