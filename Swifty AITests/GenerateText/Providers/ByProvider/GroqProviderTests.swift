import XCTest

@testable import Swifty_AI

final class GroqProviderTests: XCTestCase {
    private var provider: OpenAICompatibleProvider!

    override func setUp() {
        super.setUp()
        MockURLProtocol.handler = nil
        provider = OpenAICompatibleProvider(
            baseURL: "https://api.groq.com/openai/v1",
            apiKey: "test-key",
            model: "llama-3.3-70b-versatile",
            session: .mock
        )
    }

    func testSuccessfulGeneration() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(
                statusCode: 200,
                json: [
                    "model": "llama-3.3-70b-versatile",
                    "choices": [
                        ["message": ["content": "Hello from Groq"], "finish_reason": "stop"]
                    ],
                    "usage": ["prompt_tokens": 8, "completion_tokens": 12],
                ])
        }
        let response = try await provider.generate("Hi")
        XCTAssertEqual(response.text, "Hello from Groq")
        XCTAssertEqual(response.model, "llama-3.3-70b-versatile")
        XCTAssertEqual(response.finishReason, "stop")
        XCTAssertEqual(response.usage?.inputTokens, 8)
        XCTAssertEqual(response.usage?.outputTokens, 12)
    }

    func testSendsCorrectAuthHeader() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.handler = { request in
            capturedRequest = request
            return try mockResponse(
                statusCode: 200,
                json: [
                    "choices": [["message": ["content": "ok"], "finish_reason": "stop"]]
                ])
        }
        _ = try await provider.generate("Hi")
        XCTAssertEqual(
            capturedRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
    }

    func testSendsCorrectEndpoint() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.handler = { request in
            capturedRequest = request
            return try mockResponse(
                statusCode: 200,
                json: [
                    "choices": [["message": ["content": "ok"], "finish_reason": "stop"]]
                ])
        }
        _ = try await provider.generate("Hi")
        XCTAssertEqual(
            capturedRequest?.url?.absoluteString, "https://api.groq.com/openai/v1/chat/completions")
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

    func testLiveGroqGeneration() async throws {
        guard let apiKey = ProcessInfo.processInfo.environment["GROQ_API_KEY"], !apiKey.isEmpty
        else {
            throw XCTSkip("Set GROQ_API_KEY to run the live Groq integration test.")
        }
        let liveProvider = OpenAICompatibleProvider(
            baseURL: "https://api.groq.com/openai/v1",
            apiKey: apiKey,
            model: "llama-3.3-70b-versatile"
        )
        let response = try await liveProvider.generate("Reply with exactly: ok")
        XCTAssertFalse(response.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
