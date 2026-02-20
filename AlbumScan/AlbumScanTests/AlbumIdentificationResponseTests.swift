import Testing
import Foundation
@testable import AlbumScan

@Suite("AlbumIdentificationResponse Tests")
struct AlbumIdentificationResponseTests {

    // MARK: - Helpers

    private func jsonData(_ dict: [String: Any]) -> Data {
        try! JSONSerialization.data(withJSONObject: dict)
    }

    private var successJSON: [String: Any] {
        [
            "success": true,
            "artistName": "Radiohead",
            "albumTitle": "OK Computer",
            "releaseYear": "1997",
            "genres": ["Alternative Rock", "Art Rock"],
            "recordLabel": "Parlophone",
            "confidence": "high",
            "rationale": "Clear text match",
            "observation": [
                "extractedText": "RADIOHEAD OK COMPUTER",
                "albumDescription": "An astronaut floating in space",
                "textConfidence": "high",
                "labelLogoVisible": false,
                "visuallyDistinctive": true,
                "additionalDetails": nil as String?
            ] as [String: Any?]
        ]
    }

    private var searchNeededJSON: [String: Any] {
        [
            "success": false,
            "needSearch": true,
            "searchRequest": [
                "strategy": "metadata",
                "query": "album with astronaut cover",
                "reason": "Text not readable",
                "observation": [
                    "extractedText": "",
                    "albumDescription": "An astronaut",
                    "textConfidence": "low",
                    "labelLogoVisible": false,
                    "visuallyDistinctive": true
                ] as [String: Any]
            ] as [String: Any]
        ]
    }

    private var unresolvedJSON: [String: Any] {
        [
            "success": false,
            "needSearch": false,
            "errorMessage": "Could not identify this album"
        ]
    }

    // MARK: - Tests

    @Test func parsesSuccessResponse() throws {
        let data = jsonData(successJSON)
        let result = try AlbumIdentificationResponse.parse(from: data)

        if case .success(let identification) = result {
            #expect(identification.artistName == "Radiohead")
            #expect(identification.albumTitle == "OK Computer")
            #expect(identification.confidence == "high")
        } else {
            Issue.record("Expected .success, got \(result)")
        }
    }

    @Test func parsesSearchNeededResponse() throws {
        let data = jsonData(searchNeededJSON)
        let result = try AlbumIdentificationResponse.parse(from: data)

        if case .searchNeeded(let fallback) = result {
            #expect(fallback.needSearch == true)
            #expect(fallback.searchRequest.strategy == .metadata)
        } else {
            Issue.record("Expected .searchNeeded, got \(result)")
        }
    }

    @Test func parsesUnresolvedResponse() throws {
        let data = jsonData(unresolvedJSON)
        let result = try AlbumIdentificationResponse.parse(from: data)

        if case .unresolved(let unresolved) = result {
            #expect(unresolved.errorMessage == "Could not identify this album")
        } else {
            Issue.record("Expected .unresolved, got \(result)")
        }
    }

    @Test func invalidJSONThrowsError() {
        let badData = "not json".data(using: .utf8)!
        #expect(throws: APIError.self) {
            _ = try AlbumIdentificationResponse.parse(from: badData)
        }
    }

    @Test func successfulIdentificationConvertsToPhase1Response() throws {
        let data = jsonData(successJSON)
        let result = try AlbumIdentificationResponse.parse(from: data)

        if case .success(let identification) = result {
            let phase1 = identification.toPhase1Response()
            #expect(phase1.isSuccess == true)
            #expect(phase1.artistName == "Radiohead")
            #expect(phase1.albumTitle == "OK Computer")
            #expect(phase1.releaseYear == "1997")
        } else {
            Issue.record("Expected .success")
        }
    }
}
