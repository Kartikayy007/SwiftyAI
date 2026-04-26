import XCTest
@testable import Swifty_AI

final class OllamaProviderTests: XCTestCase {
    private var provider: OpenAICompatibleProvider!

    override func setUp() {
        super.setUp()
        MockURLProtocol.handler = nil
        provider = OpenAICompatibleProvider(
            baseURL: "http://localhost:11434/v1",
            apiKey: "ollama",
            model: "llama3.2",
            session: .mock
        )
    }

    func testSuccessfulGeneration() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(statusCode: 200, json: [
                "model": "llama3.2",
                "choices": [["message": ["content": "Hello from Ollama"], "finish_reason": "stop"]],
                "usage": ["prompt_tokens": 8, "completion_tokens": 12]
            ])
        }
        let response = try await provider.generate("Hi")
        XCTAssertEqual(response.text, "Hello from Ollama")
        XCTAssertEqual(response.model, "llama3.2")
        XCTAssertEqual(response.finishReason, "stop")
        XCTAssertEqual(response.usage?.inputTokens, 8)
        XCTAssertEqual(response.usage?.outputTokens, 12)
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
        XCTAssertEqual(capturedRequest?.url?.absoluteString, "http://localhost:11434/v1/chat/completions")
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
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer ollama")
    }

    func testCustomBaseURL() async throws {
        let customProvider = OpenAICompatibleProvider(
            baseURL: "http://localhost:8080/v1",
            apiKey: "ollama",
            model: "llama3.2",
            session: .mock
        )
        var capturedRequest: URLRequest?
        MockURLProtocol.handler = { request in
            capturedRequest = request
            return try mockResponse(statusCode: 200, json: [
                "choices": [["message": ["content": "ok"], "finish_reason": "stop"]]
            ])
        }
        _ = try await customProvider.generate("Hi")
        XCTAssertEqual(capturedRequest?.url?.absoluteString, "http://localhost:8080/v1/chat/completions")
    }

    func testAPIErrorThrowsCorrectly() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(statusCode: 404, json: ["error": ["message": "Model not found"]])
        }
        do {
            _ = try await provider.generate("Hi")
            XCTFail("Expected apiError")
        } catch AIError.apiError(let statusCode, let message) {
            XCTAssertEqual(statusCode, 404)
            XCTAssertEqual(message, "Model not found")
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

    func testLiveOllamaGeneration() async throws {
        guard let model = ProcessInfo.processInfo.environment["OLLAMA_MODEL"], !model.isEmpty else {
            throw XCTSkip("Set OLLAMA_MODEL (e.g. llama3.2) and ensure Ollama is running to run the live Ollama test.")
        }
        let liveProvider = OpenAICompatibleProvider(
            baseURL: "http://localhost:11434/v1",
            apiKey: "ollama",
            model: model
        )
        let response = try await liveProvider.generate("Reply with exactly: ok")
        XCTAssertFalse(response.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
