import XCTest

@testable import Swifty_AI

final class AnthropicProviderTests: XCTestCase {
    private var provider: AnthropicProvider!

    override func setUp() {
        super.setUp()
        MockURLProtocol.handler = nil
        provider = AnthropicProvider(apiKey: "test-key", model: "claude-3-5-sonnet", session: .mock)
    }

    func testSuccessfulGeneration() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(
                statusCode: 200,
                json: [
                    "model": "claude-3-5-sonnet",
                    "content": [["type": "text", "text": "Hello from Anthropic"]],
                    "stop_reason": "end_turn",
                    "usage": ["input_tokens": 10, "output_tokens": 25],
                ])
        }
        let response = try await provider.generate("Hi")
        XCTAssertEqual(response.text, "Hello from Anthropic")
        XCTAssertEqual(response.model, "claude-3-5-sonnet")
        XCTAssertEqual(response.finishReason, "end_turn")
        XCTAssertEqual(response.usage?.inputTokens, 10)
        XCTAssertEqual(response.usage?.outputTokens, 25)
    }

    func testNonTextBlocksAreIgnored() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(
                statusCode: 200,
                json: [
                    "content": [
                        ["type": "tool_use", "id": "toolu_01"],
                        ["type": "text", "text": "Here is the result"],
                    ],
                    "stop_reason": "tool_use",
                ])
        }
        let response = try await provider.generate("Hi")
        XCTAssertEqual(response.text, "Here is the result")
    }

    func testAllNonTextBlocksThrowsInvalidResponse() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(
                statusCode: 200,
                json: [
                    "content": [["type": "tool_use", "id": "toolu_01"]]
                ])
        }
        do {
            _ = try await provider.generate("Hi")
            XCTFail("Expected invalidResponse")
        } catch AIError.invalidResponse {
            // pass
        }
    }

    func testSendsCorrectHeaders() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.handler = { request in
            capturedRequest = request
            return try mockResponse(
                statusCode: 200,
                json: [
                    "content": [["type": "text", "text": "ok"]]
                ])
        }
        _ = try await provider.generate("Hi")
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "x-api-key"), "test-key")
        XCTAssertEqual(
            capturedRequest?.value(forHTTPHeaderField: "anthropic-version"), "2023-06-01")
    }

    func testSendsCorrectEndpoint() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.handler = { request in
            capturedRequest = request
            return try mockResponse(
                statusCode: 200,
                json: [
                    "content": [["type": "text", "text": "ok"]]
                ])
        }
        _ = try await provider.generate("Hi")
        XCTAssertEqual(
            capturedRequest?.url?.absoluteString, "https://api.anthropic.com/v1/messages")
    }

    func testAPIErrorThrowsCorrectly() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(statusCode: 429, json: ["error": ["message": "Rate limit exceeded"]])
        }
        do {
            _ = try await provider.generate("Hi")
            XCTFail("Expected apiError")
        } catch AIError.apiError(let statusCode, let message) {
            XCTAssertEqual(statusCode, 429)
            XCTAssertEqual(message, "Rate limit exceeded")
        }
    }

    func testLiveAnthropicGeneration() async throws {
        guard let apiKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !apiKey.isEmpty
        else {
            throw XCTSkip("Set ANTHROPIC_API_KEY to run the live Anthropic integration test.")
        }
        let liveProvider = AnthropicProvider(apiKey: apiKey, model: "claude-3-5-sonnet-latest")
        let response = try await liveProvider.generate("Reply with exactly: ok")
        XCTAssertFalse(response.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
