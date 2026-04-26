import XCTest
@testable import Swifty_AI

final class OllamaStreamTests: XCTestCase {
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

    func testChunksAccumulate() async throws {
        MockURLProtocol.handler = { _ in
            try mockSSEResponse(chunks: [
                ["choices": [["delta": ["content": "Hi"], "finish_reason": NSNull()]]],
                ["choices": [["delta": ["content": NSNull()], "finish_reason": "stop"]]]
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
        XCTAssertEqual(capturedURL, "http://localhost:11434/v1/chat/completions")
    }

    func testLiveStream() async throws {
        guard let model = ProcessInfo.processInfo.environment["OLLAMA_MODEL"], !model.isEmpty else {
            throw XCTSkip("Set OLLAMA_MODEL and ensure Ollama is running to run live Ollama stream test.")
        }
        let live = OpenAICompatibleProvider(baseURL: "http://localhost:11434/v1", apiKey: "ollama", model: model)
        var full = ""
        var lastChunk: AIStreamChunk?
        var chunkCount = 0
        print("[Ollama stream] starting...")
        for try await chunk in live.stream("Say hi in one sentence") {
            full += chunk.text
            chunkCount += 1
            print("[Ollama chunk \(chunkCount)] \"\(chunk.text)\"")
            lastChunk = chunk
        }
        print("[Ollama stream] done — \(chunkCount) chunks, full response: \"\(full)\"")
        if let reason = lastChunk?.finishReason { print("[Ollama stream] finish reason: \(reason)") }
        if let usage = lastChunk?.usage { print("[Ollama stream] tokens — in: \(usage.inputTokens), out: \(usage.outputTokens)") }
        XCTAssertFalse(full.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
