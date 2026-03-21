import XCTest
@testable import Memo

final class WhisperServiceTests: XCTestCase {
    private let service = WhisperService()

    // MARK: - API Key validation

    func test_transcribe_throwsMissingKey_whenEmpty() async {
        await assertThrowsMissingAPIKey(apiKey: "")
    }

    func test_transcribe_throwsMissingKey_whenWhitespaceOnly() async {
        await assertThrowsMissingAPIKey(apiKey: "   ")
    }

    // MARK: - Error descriptions

    func test_missingAPIKey_descriptionMentionsSettings() {
        let err = WhisperError.missingAPIKey
        XCTAssertTrue(err.errorDescription?.contains("Settings") ?? false)
    }

    func test_emptyResponse_hasDescription() {
        XCTAssertNotNil(WhisperError.emptyResponse.errorDescription)
    }

    func test_httpError_parsesOpenAIErrorJSON() {
        let body = #"{"error":{"message":"Invalid API key","type":"invalid_request_error"}}"#
        let err = WhisperError.httpError(401, body)
        XCTAssertTrue(err.errorDescription?.contains("Invalid API key") ?? false)
    }

    func test_httpError_fallsBackToRawBody_whenNotJSON() {
        let err = WhisperError.httpError(500, "Internal Server Error")
        XCTAssertTrue(err.errorDescription?.contains("500") ?? false)
        XCTAssertTrue(err.errorDescription?.contains("Internal Server Error") ?? false)
    }

    func test_httpError_fallsBackToRawBody_whenJSONMalformed() {
        let err = WhisperError.httpError(400, "{not valid json}")
        XCTAssertTrue(err.errorDescription?.contains("400") ?? false)
    }

    // MARK: - Helpers

    private func assertThrowsMissingAPIKey(apiKey: String, file: StaticString = #file, line: UInt = #line) async {
        do {
            _ = try await service.transcribe(
                audioURL: URL(fileURLWithPath: "/dev/null"),
                apiKey: apiKey,
                language: nil
            )
            XCTFail("Expected WhisperError.missingAPIKey", file: file, line: line)
        } catch WhisperError.missingAPIKey {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)", file: file, line: line)
        }
    }
}
