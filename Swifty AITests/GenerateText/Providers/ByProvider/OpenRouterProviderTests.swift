import XCTest
@testable import Swifty_AI

final class OpenRouterProviderTests: XCTestCase {
    private var provider: OpenAICompatibleProvider!

    override func setUp() {
        super.setUp()
        MockURLProtocol.handler = nil
        provider = OpenAICompatibleProvider(
            baseURL: "https://openrouter.ai/api/v1",
            apiKey: "test-key",
            model: "meta-llama/llama-3.3-70b-instruct:free",
            session: .mock
        )
    }

    func testSuccessfulGeneration() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(statusCode: 200, json: [
                "model": "meta-llama/llama-3.3-70b-instruct:free",
                "choices": [["message": ["content": "Hello from OpenRouter"], "finish_reason": "stop"]],
                "usage": ["prompt_tokens": 10, "completion_tokens": 15]
            ])
        }
        let response = try await provider.generate("Hi")
        XCTAssertEqual(response.text, "Hello from OpenRouter")
        XCTAssertEqual(response.model, "meta-llama/llama-3.3-70b-instruct:free")
        XCTAssertEqual(response.finishReason, "stop")
        XCTAssertEqual(response.usage?.inputTokens, 10)
        XCTAssertEqual(response.usage?.outputTokens, 15)
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
        XCTAssertEqual(capturedRequest?.url?.absoluteString, "https://openrouter.ai/api/v1/chat/completions")
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

    func testLiveOpenRouterGeneration() async throws {
        guard let apiKey = ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"], !apiKey.isEmpty else {
            throw XCTSkip("Set OPENROUTER_API_KEY to run the live OpenRouter integration test.")
        }
        let liveProvider = OpenAICompatibleProvider(
            baseURL: "https://openrouter.ai/api/v1",
            apiKey: apiKey,
            model: "meta-llama/llama-3.3-70b-instruct:free"
        )
        let response = try await liveProvider.generate("Reply with exactly: ok")
        XCTAssertFalse(response.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
