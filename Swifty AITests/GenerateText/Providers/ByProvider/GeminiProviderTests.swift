import XCTest
@testable import Swifty_AI

final class GeminiProviderTests: XCTestCase {
    private var provider: GeminiProvider!

    override func setUp() {
        super.setUp()
        MockURLProtocol.handler = nil
        provider = GeminiProvider(apiKey: "test-key", model: "gemini-2.5-flash", session: .mock)
    }

    func testSuccessfulGeneration() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(statusCode: 200, json: [
                "modelVersion": "gemini-2.5-flash",
                "candidates": [["content": ["parts": [["text": "Hello from Gemini"]]], "finishReason": "STOP"]],
                "usageMetadata": ["promptTokenCount": 5, "candidatesTokenCount": 15]
            ])
        }
        let response = try await provider.generate("Hi")
        XCTAssertEqual(response.text, "Hello from Gemini")
        XCTAssertEqual(response.model, "gemini-2.5-flash")
        XCTAssertEqual(response.finishReason, "STOP")
        XCTAssertEqual(response.usage?.inputTokens, 5)
        XCTAssertEqual(response.usage?.outputTokens, 15)
    }

    func testSendsCorrectAPIKeyHeader() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.handler = { request in
            capturedRequest = request
            return try mockResponse(statusCode: 200, json: [
                "candidates": [["content": ["parts": [["text": "ok"]]], "finishReason": "STOP"]]
            ])
        }
        _ = try await provider.generate("Hi")
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "x-goog-api-key"), "test-key")
    }

    func testSendsCorrectEndpointWithModel() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.handler = { request in
            capturedRequest = request
            return try mockResponse(statusCode: 200, json: [
                "candidates": [["content": ["parts": [["text": "ok"]]], "finishReason": "STOP"]]
            ])
        }
        _ = try await provider.generate("Hi")
        XCTAssertEqual(
            capturedRequest?.url?.absoluteString,
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
        )
    }

    func testAPIErrorThrowsCorrectly() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(statusCode: 403, json: ["error": ["message": "API key invalid"]])
        }
        do {
            _ = try await provider.generate("Hi")
            XCTFail("Expected apiError")
        } catch AIError.apiError(let statusCode, let message) {
            XCTAssertEqual(statusCode, 403)
            XCTAssertEqual(message, "API key invalid")
        }
    }

    func testEmptyCandidatesThrowsInvalidResponse() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(statusCode: 200, json: ["candidates": []])
        }
        do {
            _ = try await provider.generate("Hi")
            XCTFail("Expected invalidResponse")
        } catch AIError.invalidResponse {
            // pass
        }
    }

    func testLiveGeminiGeneration() async throws {
        guard let apiKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !apiKey.isEmpty else {
            throw XCTSkip("Set GEMINI_API_KEY to run the live Gemini integration test.")
        }
        let liveProvider = GeminiProvider(apiKey: apiKey, model: "gemini-2.5-flash")
        let response = try await liveProvider.generate("Reply with exactly: ok")
        XCTAssertFalse(response.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
