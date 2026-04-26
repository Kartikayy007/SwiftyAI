import XCTest

@testable import Swifty_AI

final class CloudflareStreamTests: XCTestCase {
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

    func testChunksAccumulate() async throws {
        MockURLProtocol.handler = { _ in
            try mockSSEResponse(chunks: [
                ["choices": [["delta": ["content": "Hi"], "finish_reason": NSNull()]]],
                ["choices": [["delta": ["content": NSNull()], "finish_reason": "stop"]]],
            ])
        }
        var texts: [String] = []
        for try await chunk in provider.stream("Hi") {
            if !chunk.text.isEmpty { texts.append(chunk.text) }
        }
        XCTAssertEqual(texts.joined(), "Hi")
    }

    func testSendsCorrectEndpoint() async throws {
        var capturedURL: String?
        MockURLProtocol.handler = { request in
            capturedURL = request.url?.absoluteString
            return try mockSSEResponse(chunks: [
                ["choices": [["delta": ["content": NSNull()], "finish_reason": "stop"]]]
            ])
        }
        for try await _ in provider.stream("Hi") {}
        XCTAssertEqual(
            capturedURL,
            "https://api.cloudflare.com/client/v4/accounts/test-account-id/ai/v1/chat/completions"
        )
    }

    func testLiveStream() async throws {
        guard let apiKey = ProcessInfo.processInfo.environment["CLOUDFLARE_API_KEY"], !apiKey.isEmpty
        else {
            throw XCTSkip("Set CLOUDFLARE_API_KEY to run live Cloudflare stream test.")
        }
        guard let accountID = ProcessInfo.processInfo.environment["CLOUDFLARE_ACCOUNT_ID"], !accountID.isEmpty
        else {
            throw XCTSkip("Set CLOUDFLARE_ACCOUNT_ID to run live Cloudflare stream test.")
        }
        let live = OpenAICompatibleProvider(
            baseURL: "https://api.cloudflare.com/client/v4/accounts/\(accountID)/ai/v1",
            apiKey: apiKey,
            model: "@cf/meta/llama-3.3-70b-instruct-fp8-fast")
        var full = ""
        var lastChunk: AIStreamChunk?
        var chunkCount = 0
        print("[Cloudflare stream] starting...")
        for try await chunk in live.stream("Say hi in one sentence") {
            full += chunk.text
            chunkCount += 1
            print("[Cloudflare chunk \(chunkCount)] \"\(chunk.text)\"")
            lastChunk = chunk
        }
        print("[Cloudflare stream] done — \(chunkCount) chunks, full response: \"\(full)\"")
        if let reason = lastChunk?.finishReason { print("[Cloudflare stream] finish reason: \(reason)") }
        if let usage = lastChunk?.usage {
            print("[Cloudflare stream] tokens — in: \(usage.inputTokens), out: \(usage.outputTokens)")
        }
        XCTAssertFalse(full.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
