import XCTest
@testable import Swifty_AI

final class GeminiStreamTests: XCTestCase {
    private var provider: GeminiProvider!

    override func setUp() {
        super.setUp()
        MockURLProtocol.handler = nil
        provider = GeminiProvider(apiKey: "test-key", model: "gemini-2.5-flash", session: .mock)
    }

    func testChunksAccumulate() async throws {
        MockURLProtocol.handler = { _ in
            try mockSSEResponse(chunks: [
                ["candidates": [["content": ["parts": [["text": "Hello"]]], "finishReason": NSNull()]]],
                ["candidates": [["content": ["parts": [["text": " world"]]], "finishReason": "STOP"]],
                 "usageMetadata": ["promptTokenCount": 3, "candidatesTokenCount": 5]]
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
                ["candidates": [["content": ["parts": [["text": "Hi"]]], "finishReason": "STOP"]]]
            ])
        }
        var lastChunk: AIStreamChunk?
        for try await chunk in provider.stream("Hi") {
            lastChunk = chunk
        }
        XCTAssertEqual(lastChunk?.finishReason, "STOP")
    }

    func testUsageOnLastChunk() async throws {
        MockURLProtocol.handler = { _ in
            try mockSSEResponse(chunks: [
                ["candidates": [["content": ["parts": [["text": "Hi"]]], "finishReason": "STOP"]],
                 "usageMetadata": ["promptTokenCount": 4, "candidatesTokenCount": 6]]
            ])
        }
        var lastChunk: AIStreamChunk?
        for try await chunk in provider.stream("Hi") {
            lastChunk = chunk
        }
        XCTAssertEqual(lastChunk?.usage?.inputTokens, 4)
        XCTAssertEqual(lastChunk?.usage?.outputTokens, 6)
    }

    func testSendsCorrectEndpoint() async throws {
        var capturedURL: String?
        MockURLProtocol.handler = { request in
            capturedURL = request.url?.absoluteString
            return try mockSSEResponse(chunks: [
                ["candidates": [["content": ["parts": [["text": "ok"]]], "finishReason": "STOP"]]]
            ])
        }
        for try await _ in provider.stream("Hi") {}
        XCTAssertTrue(capturedURL?.contains("streamGenerateContent") == true)
        XCTAssertTrue(capturedURL?.contains("alt=sse") == true)
    }

    func testAPIErrorThrows() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(statusCode: 403, json: ["error": ["message": "API key invalid"]])
        }
        do {
            for try await _ in provider.stream("Hi") {}
            XCTFail("Expected apiError")
        } catch AIError.apiError(let code, _) {
            XCTAssertEqual(code, 403)
        }
    }

    func testLiveStream() async throws {
        guard let apiKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !apiKey.isEmpty else {
            throw XCTSkip("Set GEMINI_API_KEY to run live Gemini stream test.")
        }
        let live = GeminiProvider(apiKey: apiKey, model: "gemini-2.5-flash")
        var full = ""
        var lastChunk: AIStreamChunk?
        var chunkCount = 0
        print("[Gemini stream] starting...")
        for try await chunk in live.stream("Say hi in one sentence") {
            full += chunk.text
            chunkCount += 1
            print("[Gemini chunk \(chunkCount)] \"\(chunk.text)\"")
            lastChunk = chunk
        }
        print("[Gemini stream] done — \(chunkCount) chunks, full response: \"\(full)\"")
        if let reason = lastChunk?.finishReason { print("[Gemini stream] finish reason: \(reason)") }
        if let usage = lastChunk?.usage { print("[Gemini stream] tokens — in: \(usage.inputTokens), out: \(usage.outputTokens)") }
        XCTAssertFalse(full.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
