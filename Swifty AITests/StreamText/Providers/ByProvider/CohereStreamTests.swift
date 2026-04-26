import XCTest

@testable import Swifty_AI

final class CohereStreamTests: XCTestCase {
    private var provider: OpenAICompatibleProvider!

    override func setUp() {
        super.setUp()
        MockURLProtocol.handler = nil
        provider = OpenAICompatibleProvider(
            baseURL: "https://api.cohere.com/compatibility/v1",
            apiKey: "test-key",
            model: "command-r-plus",
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
        XCTAssertEqual(capturedURL, "https://api.cohere.com/compatibility/v1/chat/completions")
    }

    func testLiveStream() async throws {
        guard let apiKey = ProcessInfo.processInfo.environment["COHERE_API_KEY"], !apiKey.isEmpty
        else {
            throw XCTSkip("Set COHERE_API_KEY to run live Cohere stream test.")
        }
        let live = OpenAICompatibleProvider(
            baseURL: "https://api.cohere.com/compatibility/v1", apiKey: apiKey,
            model: "command-a-03-2025")
        var full = ""
        var lastChunk: AIStreamChunk?
        var chunkCount = 0
        print("[Cohere stream] starting...")
        for try await chunk in live.stream("Say hi in one sentence") {
            full += chunk.text
            chunkCount += 1
            print("[Cohere chunk \(chunkCount)] \"\(chunk.text)\"")
            lastChunk = chunk
        }
        print("[Cohere stream] done — \(chunkCount) chunks, full response: \"\(full)\"")
        if let reason = lastChunk?.finishReason { print("[Cohere stream] finish reason: \(reason)") }
        if let usage = lastChunk?.usage {
            print("[Cohere stream] tokens — in: \(usage.inputTokens), out: \(usage.outputTokens)")
        }
        XCTAssertFalse(full.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
