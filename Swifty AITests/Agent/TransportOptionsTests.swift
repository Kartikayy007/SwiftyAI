import XCTest
@testable import Swifty_AI

final class TransportOptionsTests: XCTestCase {
    func testPerRequestHeadersAreSent() async throws {
        var requestID: String?
        MockURLProtocol.handler = { request in
            requestID = request.value(forHTTPHeaderField: "X-Request-ID")
            return try mockResponse(statusCode: 200, json: [
                "id": "chatcmpl-test",
                "object": "chat.completion",
                "model": "gpt-4o-mini",
                "choices": [["index": 0, "message": ["role": "assistant", "content": "ok"], "finish_reason": "stop"]],
                "usage": ["prompt_tokens": 1, "completion_tokens": 1]
            ])
        }

        let provider = OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: "test", model: "gpt-4o-mini", session: .mock)
        _ = try await generateText(model: provider, prompt: "hi", options: GenerationOptions(headers: ["X-Request-ID": "abc123"]))

        XCTAssertEqual(requestID, "abc123")
    }

    func testRetryPolicyRetriesRetryableStatusCode() async throws {
        var attempts = 0
        MockURLProtocol.handler = { _ in
            attempts += 1
            if attempts == 1 {
                return try mockResponse(statusCode: 500, json: ["error": ["message": "temporary"]])
            }
            return try mockResponse(statusCode: 200, json: [
                "id": "chatcmpl-test",
                "object": "chat.completion",
                "model": "gpt-4o-mini",
                "choices": [["index": 0, "message": ["role": "assistant", "content": "ok"], "finish_reason": "stop"]],
                "usage": ["prompt_tokens": 1, "completion_tokens": 1]
            ])
        }

        let provider = OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: "test", model: "gpt-4o-mini", session: .mock)
        let response = try await generateText(
            model: provider,
            prompt: "hi",
            options: GenerationOptions(retryPolicy: RetryPolicy(maxAttempts: 2, baseDelay: .zero))
        )

        XCTAssertEqual(response.text, "ok")
        XCTAssertEqual(attempts, 2)
    }
}

