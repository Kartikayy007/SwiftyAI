import XCTest
@testable import Swifty_AI

final class AnthropicStreamTests: XCTestCase {
    private var provider: AnthropicProvider!

    override func setUp() {
        super.setUp()
        MockURLProtocol.handler = nil
        provider = AnthropicProvider(apiKey: "test-key", model: "claude-3-5-sonnet", session: .mock)
    }

    func testChunksAccumulate() async throws {
        MockURLProtocol.handler = { _ in
            try mockAnthropicSSEResponse(textDeltas: ["Hello", " world"], stopReason: "end_turn")
        }
        var texts: [String] = []
        for try await chunk in provider.stream("Hi") {
            if !chunk.text.isEmpty { texts.append(chunk.text) }
        }
        XCTAssertEqual(texts.joined(), "Hello world")
    }

    func testFinishReasonOnLastChunk() async throws {
        MockURLProtocol.handler = { _ in
            try mockAnthropicSSEResponse(textDeltas: ["Hi"], stopReason: "end_turn")
        }
        var lastChunk: AIStreamChunk?
        for try await chunk in provider.stream("Hi") {
            lastChunk = chunk
        }
        XCTAssertEqual(lastChunk?.finishReason, "end_turn")
    }

    func testUsageOnLastChunk() async throws {
        MockURLProtocol.handler = { _ in
            try mockAnthropicSSEResponse(
                textDeltas: ["Hi"],
                stopReason: "end_turn",
                inputTokens: 8,
                outputTokens: 3
            )
        }
        var lastChunk: AIStreamChunk?
        for try await chunk in provider.stream("Hi") {
            lastChunk = chunk
        }
        XCTAssertEqual(lastChunk?.usage?.inputTokens, 8)
        XCTAssertEqual(lastChunk?.usage?.outputTokens, 3)
    }

    func testSendsStreamTrue() async throws {
        var capturedBody: [String: Any]?
        MockURLProtocol.handler = { request in
            if let body = request.httpBody {
                capturedBody = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
            }
            return try mockAnthropicSSEResponse(textDeltas: [], stopReason: "end_turn")
        }
        for try await _ in provider.stream("Hi") {}
        XCTAssertEqual(capturedBody?["stream"] as? Bool, true)
    }

    func testAPIErrorThrows() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(statusCode: 529, json: ["error": ["message": "Overloaded"]])
        }
        do {
            for try await _ in provider.stream("Hi") {}
            XCTFail("Expected apiError")
        } catch AIError.apiError(let code, _) {
            XCTAssertEqual(code, 529)
        }
    }

    func testLiveStream() async throws {
        guard let apiKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !apiKey.isEmpty else {
            throw XCTSkip("Set ANTHROPIC_API_KEY to run live Anthropic stream test.")
        }
        let live = AnthropicProvider(apiKey: apiKey, model: "claude-haiku-4-5-20251001")
        var full = ""
        var lastChunk: AIStreamChunk?
        var chunkCount = 0
        print("[Anthropic stream] starting...")
        for try await chunk in live.stream("Say hi in one sentence") {
            full += chunk.text
            chunkCount += 1
            print("[Anthropic chunk \(chunkCount)] \"\(chunk.text)\"")
            lastChunk = chunk
        }
        print("[Anthropic stream] done — \(chunkCount) chunks, full response: \"\(full)\"")
        if let reason = lastChunk?.finishReason { print("[Anthropic stream] finish reason: \(reason)") }
        if let usage = lastChunk?.usage { print("[Anthropic stream] tokens — in: \(usage.inputTokens), out: \(usage.outputTokens)") }
        XCTAssertFalse(full.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
