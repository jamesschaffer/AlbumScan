import Testing
@testable import AlbumScan

@Suite("ScanState Tests")
struct ScanStateTests {

    // MARK: - isProcessing

    @Test func idleIsNotProcessing() {
        #expect(ScanState.idle.isProcessing == false)
    }

    @Test func identifyingIsProcessing() {
        #expect(ScanState.identifying.isProcessing == true)
    }

    @Test func identifiedIsProcessing() {
        #expect(ScanState.identified.isProcessing == true)
    }

    @Test func loadingReviewIsProcessing() {
        #expect(ScanState.loadingReview.isProcessing == true)
    }

    @Test func completeIsNotProcessing() {
        #expect(ScanState.complete.isProcessing == false)
    }

    @Test func identificationFailedIsNotProcessing() {
        #expect(ScanState.identificationFailed.isProcessing == false)
    }

    @Test func reviewFailedIsNotProcessing() {
        #expect(ScanState.reviewFailed.isProcessing == false)
    }

    // MARK: - isLoading

    @Test func identifyingIsLoading() {
        #expect(ScanState.identifying.isLoading == true)
    }

    @Test func loadingReviewIsLoading() {
        #expect(ScanState.loadingReview.isLoading == true)
    }

    @Test func identifiedIsNotLoading() {
        #expect(ScanState.identified.isLoading == false)
    }

    // MARK: - description

    @Test func descriptionsAreCorrect() {
        #expect(ScanState.idle.description == "Ready to scan")
        #expect(ScanState.identifying.description == "Identifying album...")
        #expect(ScanState.identified.description == "Album identified")
        #expect(ScanState.loadingReview.description == "Loading review...")
        #expect(ScanState.complete.description == "Complete")
        #expect(ScanState.identificationFailed.description == "Identification failed")
        #expect(ScanState.reviewFailed.description == "Review unavailable")
    }
}
