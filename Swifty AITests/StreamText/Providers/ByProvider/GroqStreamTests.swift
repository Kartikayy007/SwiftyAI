import XCTest

@testable import Swifty_AI

final class GroqStreamTests: XCTestCase {
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
        XCTAssertEqual(capturedURL, "https://api.groq.com/openai/v1/chat/completions")
    }

    func testLiveStream() async throws {
        guard let apiKey = ProcessInfo.processInfo.environment["GROQ_API_KEY"], !apiKey.isEmpty
        else {
            throw XCTSkip("Set GROQ_API_KEY to run live Groq stream test.")
        }
        let live = OpenAICompatibleProvider(
            baseURL: "https://api.groq.com/openai/v1", apiKey: apiKey,
            model: "llama-3.3-70b-versatile")
        var full = ""
        var lastChunk: AIStreamChunk?
        var chunkCount = 0
        print("[Groq stream] starting...")
        for try await chunk in live.stream("Say hi in one sentence") {
            full += chunk.text
            chunkCount += 1
            print("[Groq chunk \(chunkCount)] \"\(chunk.text)\"")
            lastChunk = chunk
        }
        print("[Groq stream] done — \(chunkCount) chunks, full response: \"\(full)\"")
        if let reason = lastChunk?.finishReason { print("[Groq stream] finish reason: \(reason)") }
        if let usage = lastChunk?.usage {
            print("[Groq stream] tokens — in: \(usage.inputTokens), out: \(usage.outputTokens)")
        }
        XCTAssertFalse(full.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
