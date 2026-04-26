import XCTest
@testable import Swifty_AI

final class CloudflareProviderTests: XCTestCase {
    private var provider: OpenAICompatibleProvider!

    override func setUp() {
        super.setUp()
        MockURLProtocol.handler = nil
        provider = OpenAICompatibleProvider(
            baseURL: "https://api.cloudflare.com/client/v4/accounts/test-account-id/ai/v1",
            apiKey: "test-key",
            model: "@cf/meta/llama-3.3-70b-instruct-fp8-fast",
            session: .mock
        )
    }

    func testSuccessfulGeneration() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(statusCode: 200, json: [
                "model": "@cf/meta/llama-3.3-70b-instruct-fp8-fast",
                "choices": [["message": ["content": "Hello from Cloudflare"], "finish_reason": "stop"]],
                "usage": ["prompt_tokens": 6, "completion_tokens": 14]
            ])
        }
        let response = try await provider.generate("Hi")
        XCTAssertEqual(response.text, "Hello from Cloudflare")
        XCTAssertEqual(response.model, "@cf/meta/llama-3.3-70b-instruct-fp8-fast")
        XCTAssertEqual(response.finishReason, "stop")
        XCTAssertEqual(response.usage?.inputTokens, 6)
        XCTAssertEqual(response.usage?.outputTokens, 14)
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
        XCTAssertEqual(
            capturedRequest?.url?.absoluteString,
            "https://api.cloudflare.com/client/v4/accounts/test-account-id/ai/v1/chat/completions"
        )
    }

    func testAccountIDEmbeddedInURL() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.handler = { request in
            capturedRequest = request
            return try mockResponse(statusCode: 200, json: [
                "choices": [["message": ["content": "ok"], "finish_reason": "stop"]]
            ])
        }
        _ = try await provider.generate("Hi")
        XCTAssertTrue(capturedRequest?.url?.absoluteString.contains("test-account-id") == true)
    }

    func testAPIErrorThrowsCorrectly() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(statusCode: 403, json: ["error": ["message": "Forbidden"]])
        }
        do {
            _ = try await provider.generate("Hi")
            XCTFail("Expected apiError")
        } catch AIError.apiError(let statusCode, let message) {
            XCTAssertEqual(statusCode, 403)
            XCTAssertEqual(message, "Forbidden")
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

    func testLiveCloudflareGeneration() async throws {
        guard let apiKey = ProcessInfo.processInfo.environment["CLOUDFLARE_API_KEY"], !apiKey.isEmpty else {
            throw XCTSkip("Set CLOUDFLARE_API_KEY to run the live Cloudflare integration test.")
        }
        guard let accountID = ProcessInfo.processInfo.environment["CLOUDFLARE_ACCOUNT_ID"], !accountID.isEmpty else {
            throw XCTSkip("Set CLOUDFLARE_ACCOUNT_ID to run the live Cloudflare integration test.")
        }
        let liveProvider = OpenAICompatibleProvider(
            baseURL: "https://api.cloudflare.com/client/v4/accounts/\(accountID)/ai/v1",
            apiKey: apiKey,
            model: "@cf/meta/llama-3.3-70b-instruct-fp8-fast"
        )
        let response = try await liveProvider.generate("Reply with exactly: ok")
        XCTAssertFalse(response.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
