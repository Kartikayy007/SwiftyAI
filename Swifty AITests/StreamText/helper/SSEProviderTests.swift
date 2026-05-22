import XCTest
@testable import Swifty_AI

/// Tests for SSE transport behavior shared by every streaming provider.
final class SSEProviderTests: XCTestCase {

    func testSSENon2xxParsesProviderErrorMessage() async throws {
        MockURLProtocol.handler = { _ in
            let body = #"{"error":{"message":"bad request"}}"#.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://mock")!,
                statusCode: 400,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, body)
        }

        let provider = OpenAICompatibleProvider(
            baseURL: "https://api.openai.com/v1",
            apiKey: "sk-test",
            model: "gpt-4o-mini",
            session: .mock
        )

        do {
            for try await _ in streamText(model: provider, prompt: "hi") {}
            XCTFail("Expected throw")
        } catch let AIError.apiError(statusCode, message) {
            XCTAssertEqual(statusCode, 400)
            XCTAssertEqual(message, "bad request")
        }
    }

    func testSSENon2xxFallsBackToHTTPStatusWhenBodyHasNoMessage() async throws {
        MockURLProtocol.handler = { _ in
            let body = Data("not json".utf8)
            let response = HTTPURLResponse(
                url: URL(string: "https://mock")!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: ["Content-Type": "text/plain"]
            )!
            return (response, body)
        }

        let provider = OpenAICompatibleProvider(
            baseURL: "https://api.openai.com/v1",
            apiKey: "sk-test",
            model: "gpt-4o-mini",
            session: .mock
        )

        do {
            for try await _ in streamText(model: provider, prompt: "hi") {}
            XCTFail("Expected throw")
        } catch let AIError.apiError(statusCode, message) {
            XCTAssertEqual(statusCode, 500)
            // Falls back to body string when no error.message JSON found.
            XCTAssertEqual(message, "not json")
        }
    }

    func testSSERetriesOnRetryableStatusCode() async throws {
        var attempts = 0
        MockURLProtocol.handler = { _ in
            attempts += 1
            if attempts == 1 {
                let body = #"{"error":{"message":"unavailable"}}"#.data(using: .utf8)!
                let response = HTTPURLResponse(
                    url: URL(string: "https://mock")!,
                    statusCode: 503,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, body)
            }
            // Second attempt: succeed
            return try mockSSEResponse(chunks: [
                ["id": "1", "object": "chat.completion.chunk", "model": "gpt-4o-mini", "choices": [["index": 0, "delta": ["content": "ok"], "finish_reason": NSNull()]]],
                ["id": "2", "object": "chat.completion.chunk", "model": "gpt-4o-mini", "choices": [["index": 0, "delta": [:], "finish_reason": "stop"]]]
            ])
        }

        let provider = OpenAICompatibleProvider(
            baseURL: "https://api.openai.com/v1",
            apiKey: "sk-test",
            model: "gpt-4o-mini",
            session: .mock
        )

        var text = ""
        let options = GenerationOptions(retryPolicy: RetryPolicy(
            maxAttempts: 2,
            baseDelay: .milliseconds(1),
            maxDelay: .milliseconds(1),
            retryableStatusCodes: [503]
        ))
        for try await chunk in streamText(model: provider, prompt: "hi", options: options) {
            text += chunk.text
        }

        XCTAssertEqual(text, "ok")
        XCTAssertEqual(attempts, 2)
    }

    func testSSEDoesNotRetryNonRetryableStatusCode() async throws {
        var attempts = 0
        MockURLProtocol.handler = { _ in
            attempts += 1
            let body = #"{"error":{"message":"bad request"}}"#.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://mock")!,
                statusCode: 400,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, body)
        }

        let provider = OpenAICompatibleProvider(
            baseURL: "https://api.openai.com/v1",
            apiKey: "sk-test",
            model: "gpt-4o-mini",
            session: .mock
        )

        let options = GenerationOptions(retryPolicy: RetryPolicy(
            maxAttempts: 3,
            baseDelay: .milliseconds(1),
            retryableStatusCodes: [503]
        ))
        do {
            for try await _ in streamText(model: provider, prompt: "hi", options: options) {}
            XCTFail("Expected throw")
        } catch {}

        XCTAssertEqual(attempts, 1)
    }

    func testSSEDefaultPolicyDoesNotRetry() async throws {
        var attempts = 0
        MockURLProtocol.handler = { _ in
            attempts += 1
            let body = #"{"error":{"message":"unavailable"}}"#.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://mock")!,
                statusCode: 503,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, body)
        }

        let provider = OpenAICompatibleProvider(
            baseURL: "https://api.openai.com/v1",
            apiKey: "sk-test",
            model: "gpt-4o-mini",
            session: .mock
        )

        do {
            for try await _ in streamText(model: provider, prompt: "hi") {}
            XCTFail("Expected throw")
        } catch {}

        XCTAssertEqual(attempts, 1)
    }
}
