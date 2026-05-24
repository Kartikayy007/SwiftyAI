import XCTest

@testable import Swifty_AI

final class MistralProviderTests: XCTestCase {
    private var provider: OpenAICompatibleProvider!

    override func setUp() {
        super.setUp()
        MockURLProtocol.handler = nil
        provider = OpenAICompatibleProvider(
            baseURL: "https://api.mistral.ai/v1",
            apiKey: "test-key",
            model: "mistral-large-latest",
            session: .mock
        )
    }

    func testSuccessfulGeneration() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(
                statusCode: 200,
                json: [
                    "model": "mistral-large-latest",
                    "choices": [
                        ["message": ["content": "Hello from Mistral"], "finish_reason": "stop"]
                    ],
                    "usage": ["prompt_tokens": 9, "completion_tokens": 11],
                ])
        }
        let response = try await provider.generate("Hi")
        XCTAssertEqual(response.text, "Hello from Mistral")
        XCTAssertEqual(response.model, "mistral-large-latest")
        XCTAssertEqual(response.finishReason, "stop")
        XCTAssertEqual(response.usage?.inputTokens, 9)
        XCTAssertEqual(response.usage?.outputTokens, 11)
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
            capturedRequest?.url?.absoluteString, "https://api.mistral.ai/v1/chat/completions")
    }

    func testAPIErrorThrowsCorrectly() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(statusCode: 401, json: ["error": ["message": "Unauthorized"]])
        }
        do {
            _ = try await provider.generate("Hi")
            XCTFail("Expected apiError")
        } catch AIError.apiError(let statusCode, let message) {
            XCTAssertEqual(statusCode, 401)
            XCTAssertEqual(message, "Unauthorized")
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

    func testLiveMistralGeneration() async throws {
        guard let apiKey = ProcessInfo.processInfo.environment["MISTRAL_API_KEY"], !apiKey.isEmpty
        else {
            throw XCTSkip("Set MISTRAL_API_KEY to run the live Mistral integration test.")
        }
        let liveProvider = OpenAICompatibleProvider(
            baseURL: "https://api.mistral.ai/v1",
            apiKey: apiKey,
            model: "mistral-large-latest"
        )

        do {
            let response = try await liveProvider.generate("Reply with exactly: ok")
            XCTAssertFalse(response.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } catch {
            try skipLiveProviderError(error, provider: "Mistral")
        }
    }
}
