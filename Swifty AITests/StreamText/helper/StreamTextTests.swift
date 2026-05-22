import XCTest
@testable import Swifty_AI

final class StreamTextTests: XCTestCase {

    func testStreamMessagesWithOptionsPassesTemperatureOpenAI() async throws {
        var capturedBody: [String: Any]?
        MockURLProtocol.handler = { req in
            if let body = req.httpBody {
                capturedBody = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
            }
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

        let messages = [
            ChatMessage(role: .user, content: "hi")
        ]
        let options = GenerationOptions(temperature: 0.99, maxTokens: 64)
        for try await _ in provider.stream(messages: messages, options: options) {}

        XCTAssertEqual(capturedBody?["temperature"] as? Double, 0.99)
        XCTAssertEqual(capturedBody?["max_tokens"] as? Int, 64)
    }

    func testStreamMessagesWithOptionsPassesTemperatureAnthropic() async throws {
        var capturedBody: [String: Any]?
        MockURLProtocol.handler = { req in
            if let body = req.httpBody {
                capturedBody = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
            }
            return try mockAnthropicSSEResponse(textDeltas: ["ok"], stopReason: "end_turn")
        }

        let provider = AnthropicProvider(apiKey: "test", model: "claude-haiku-4-5-20251001", session: .mock)
        let messages = [ChatMessage(role: .user, content: "hi")]
        let options = GenerationOptions(system: "Be brief.", temperature: 0.42, maxTokens: 128)

        for try await _ in provider.stream(messages: messages, options: options) {}

        XCTAssertEqual(capturedBody?["temperature"] as? Double, 0.42)
        XCTAssertEqual(capturedBody?["max_tokens"] as? Int, 128)
        XCTAssertEqual(capturedBody?["system"] as? String, "Be brief.")
    }

    func testStreamMessagesWithOptionsPassesTemperatureGemini() async throws {
        var capturedBody: [String: Any]?
        MockURLProtocol.handler = { req in
            if let body = req.httpBody {
                capturedBody = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
            }
            // Gemini streams via SSE with chunk objects.
            let chunk: [String: Any] = [
                "candidates": [["content": ["parts": [["text": "ok"]]], "finishReason": "STOP"]],
                "usageMetadata": ["promptTokenCount": 5, "candidatesTokenCount": 2]
            ]
            return try mockSSEResponse(chunks: [chunk])
        }

        let provider = GeminiProvider(apiKey: "test", model: "gemini-2.5-flash", session: .mock)
        let messages = [ChatMessage(role: .user, content: "hi")]
        let options = GenerationOptions(temperature: 0.66, maxTokens: 100)

        for try await _ in provider.stream(messages: messages, options: options) {}

        let config = capturedBody?["generationConfig"] as? [String: Any]
        XCTAssertEqual(config?["temperature"] as? Double, 0.66)
    }

    func testStreamTextForwardsChunks() async throws {
        let model = MockAIStreamModel(chunks: [
            AIStreamChunk(text: "Hello", finishReason: nil, usage: nil),
            AIStreamChunk(text: " world", finishReason: "stop", usage: nil)
        ])
        var collected: [String] = []
        for try await chunk in streamText(model: model, prompt: "Hi") {
            collected.append(chunk.text)
        }
        XCTAssertEqual(collected, ["Hello", " world"])
    }

    func testStreamTextPropagatesError() async {
        let model = MockAIStreamModel(error: AIError.invalidResponse)
        do {
            for try await _ in streamText(model: model, prompt: "Hi") {}
            XCTFail("Expected error")
        } catch AIError.invalidResponse {
            // pass
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }
}

private struct MockAIStreamModel: AIStreamModel {
    var chunks: [AIStreamChunk] = []
    var error: Error? = nil

    func generate(_ prompt: String) async throws -> AIResponse {
        AIResponse(text: "", model: nil, usage: nil, finishReason: nil)
    }

    func stream(_ prompt: String) -> AsyncThrowingStream<AIStreamChunk, Error> {
        AsyncThrowingStream { continuation in
            if let error = error {
                continuation.finish(throwing: error)
                return
            }
            for chunk in chunks {
                continuation.yield(chunk)
            }
            continuation.finish()
        }
    }
}
