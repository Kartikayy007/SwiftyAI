import XCTest
@testable import Swifty_AI

final class OpenAIStreamTests: XCTestCase {
    private var provider: OpenAICompatibleProvider!

    override func setUp() {
        super.setUp()
        MockURLProtocol.handler = nil
        provider = OpenAICompatibleProvider(
            baseURL: "https://api.openai.com/v1",
            apiKey: "test-key",
            model: "gpt-4o-mini",
            session: .mock
        )
    }

    func testChunksAccumulate() async throws {
        MockURLProtocol.handler = { _ in
            try mockSSEResponse(chunks: [
                ["choices": [["delta": ["content": "Hello"], "finish_reason": NSNull()]]],
                ["choices": [["delta": ["content": " world"], "finish_reason": NSNull()]]],
                ["choices": [["delta": ["content": NSNull()], "finish_reason": "stop"]]]
            ])
        }
        var texts: [String] = []
        for try await chunk in provider.stream("Hi") {
            if !chunk.text.isEmpty { texts.append(chunk.text) }
        }
        XCTAssertEqual(texts.joined(), "Hello world")
    }

    func testFinishReasonOnLastChunk() async throws {
        MockURLProtocol.handler = { _ in
            try mockSSEResponse(chunks: [
                ["choices": [["delta": ["content": "Hi"], "finish_reason": NSNull()]]],
                ["choices": [["delta": ["content": NSNull()], "finish_reason": "stop"]]]
            ])
        }
        var lastChunk: AIStreamChunk?
        for try await chunk in provider.stream("Hi") {
            lastChunk = chunk
        }
        XCTAssertEqual(lastChunk?.finishReason, "stop")
    }

    func testUsageOnLastChunk() async throws {
        MockURLProtocol.handler = { _ in
            try mockSSEResponse(chunks: [
                ["choices": [["delta": ["content": "Hi"], "finish_reason": NSNull()]]],
                ["choices": [["delta": ["content": NSNull()], "finish_reason": "stop"]]],
                ["choices": [], "usage": ["prompt_tokens": 5, "completion_tokens": 10]]
            ])
        }
        var lastChunk: AIStreamChunk?
        for try await chunk in provider.stream("Hi") {
            lastChunk = chunk
        }
        XCTAssertEqual(lastChunk?.usage?.inputTokens, 5)
        XCTAssertEqual(lastChunk?.usage?.outputTokens, 10)
    }

    func testSendsStreamTrue() async throws {
        var capturedBody: [String: Any]?
        MockURLProtocol.handler = { request in
            if let body = request.httpBody {
                capturedBody = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
            }
            return try mockSSEResponse(chunks: [
                ["choices": [["delta": ["content": NSNull()], "finish_reason": "stop"]]]
            ])
        }
        for try await _ in provider.stream("Hi") {}
        XCTAssertEqual(capturedBody?["stream"] as? Bool, true)
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
        XCTAssertEqual(capturedURL, "https://api.openai.com/v1/chat/completions")
    }

    func testAPIErrorThrows() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(statusCode: 429, json: ["error": ["message": "Rate limit"]])
        }
        do {
            for try await _ in provider.stream("Hi") {}
            XCTFail("Expected apiError")
        } catch AIError.apiError(let code, _) {
            XCTAssertEqual(code, 429)
        }
    }

    func testLiveStream() async throws {
        guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !apiKey.isEmpty else {
            throw XCTSkip("Set OPENAI_API_KEY to run live OpenAI stream test.")
        }
        let live = OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: apiKey, model: "gpt-4o-mini")
        var full = ""
        var lastChunk: AIStreamChunk?
        var chunkCount = 0
        print("[OpenAI stream] starting...")
        for try await chunk in live.stream("Say hi in one sentence") {
            full += chunk.text
            chunkCount += 1
            print("[OpenAI chunk \(chunkCount)] \"\(chunk.text)\"")
            lastChunk = chunk
        }
        print("[OpenAI stream] done — \(chunkCount) chunks, full response: \"\(full)\"")
        if let reason = lastChunk?.finishReason { print("[OpenAI stream] finish reason: \(reason)") }
        if let usage = lastChunk?.usage { print("[OpenAI stream] tokens — in: \(usage.inputTokens), out: \(usage.outputTokens)") }
        XCTAssertFalse(full.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
