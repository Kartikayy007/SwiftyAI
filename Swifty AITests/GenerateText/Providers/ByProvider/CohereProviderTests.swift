import XCTest
@testable import Swifty_AI

final class CohereProviderTests: XCTestCase {
    private var provider: OpenAICompatibleProvider!

    override func setUp() {
        super.setUp()
        MockURLProtocol.handler = nil
        provider = OpenAICompatibleProvider(
            baseURL: "https://api.cohere.com/compatibility/v1",
            apiKey: "test-key",
            model: "command-r-plus",
            session: .mock
        )
    }

    func testSuccessfulGeneration() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(statusCode: 200, json: [
                "model": "command-r-plus",
                "choices": [["message": ["content": "Hello from Cohere"], "finish_reason": "stop"]],
                "usage": ["prompt_tokens": 7, "completion_tokens": 13]
            ])
        }
        let response = try await provider.generate("Hi")
        XCTAssertEqual(response.text, "Hello from Cohere")
        XCTAssertEqual(response.model, "command-r-plus")
        XCTAssertEqual(response.finishReason, "stop")
        XCTAssertEqual(response.usage?.inputTokens, 7)
        XCTAssertEqual(response.usage?.outputTokens, 13)
    }

    func testSendsCorrectAuthHeader() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.handler = { request in
            capturedRequest = request
            return try mockResponse(statusCode: 200, json: [
                "choices": [["message": ["content": "ok"], "finish_reason": "stop"]]
            ])
        }
        _ = try await provider.generate("Hi")
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
    }

    func testSendsCorrectEndpoint() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.handler = { request in
            capturedRequest = request
            return try mockResponse(statusCode: 200, json: [
                "choices": [["message": ["content": "ok"], "finish_reason": "stop"]]
            ])
        }
        _ = try await provider.generate("Hi")
        XCTAssertEqual(capturedRequest?.url?.absoluteString, "https://api.cohere.com/compatibility/v1/chat/completions")
    }

    func testAPIErrorThrowsCorrectly() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(statusCode: 402, json: ["error": ["message": "Trial limit reached"]])
        }
        do {
            _ = try await provider.generate("Hi")
            XCTFail("Expected apiError")
        } catch AIError.apiError(let statusCode, let message) {
            XCTAssertEqual(statusCode, 402)
            XCTAssertEqual(message, "Trial limit reached")
        }
    }

    func testEmptyChoicesThrowsInvalidResponse() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(statusCode: 200, json: ["choices": []])
        }
        do {
            _ = try await provider.generate("Hi")
            XCTFail("Expected invalidResponse")
        } catch AIError.invalidResponse {
            // pass
        }
    }

    func testLiveCohereGeneration() async throws {
        guard let apiKey = ProcessInfo.processInfo.environment["COHERE_API_KEY"], !apiKey.isEmpty else {
            throw XCTSkip("Set COHERE_API_KEY to run the live Cohere integration test.")
        }
        let liveProvider = OpenAICompatibleProvider(
            baseURL: "https://api.cohere.com/compatibility/v1",
            apiKey: apiKey,
            model: "command-a-03-2025"
        )
        let response = try await liveProvider.generate("Reply with exactly: ok")
        XCTAssertFalse(response.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
