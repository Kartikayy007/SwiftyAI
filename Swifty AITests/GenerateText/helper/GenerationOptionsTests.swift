import XCTest
@testable import Swifty_AI

final class GenerationOptionsTests: XCTestCase {

    // MARK: - OpenAI / OpenAI-compatible

    func testTemperatureForwardedToOpenAI() async throws {
        var capturedBody: [String: Any]?
        MockURLProtocol.handler = { req in
            if let body = req.httpBody {
                capturedBody = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
            }
            return try mockResponse(statusCode: 200, json: [
                "id": "chatcmpl-1",
                "object": "chat.completion",
                "model": "gpt-4o-mini",
                "choices": [["index": 0, "message": ["role": "assistant", "content": "ok"], "finish_reason": "stop"]],
                "usage": ["prompt_tokens": 5, "completion_tokens": 2, "total_tokens": 7]
            ])
        }

        let provider = OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: "test", model: "gpt-4o-mini", session: .mock)
        _ = try await generateText(model: provider, prompt: "hi", options: GenerationOptions(temperature: 0.3))

        XCTAssertEqual(capturedBody?["temperature"] as? Double, 0.3)
    }

    func testMaxTokensForwardedToOpenAI() async throws {
        var capturedBody: [String: Any]?
        MockURLProtocol.handler = { req in
            if let body = req.httpBody {
                capturedBody = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
            }
            return try mockResponse(statusCode: 200, json: [
                "id": "chatcmpl-2",
                "object": "chat.completion",
                "model": "gpt-4o-mini",
                "choices": [["index": 0, "message": ["role": "assistant", "content": "ok"], "finish_reason": "stop"]],
                "usage": ["prompt_tokens": 5, "completion_tokens": 2, "total_tokens": 7]
            ])
        }

        let provider = OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: "test", model: "gpt-4o-mini", session: .mock)
        _ = try await generateText(model: provider, prompt: "hi", options: GenerationOptions(maxTokens: 200))

        XCTAssertEqual(capturedBody?["max_tokens"] as? Int, 200)
    }

    func testStopSequencesForwardedToOpenAI() async throws {
        var capturedBody: [String: Any]?
        MockURLProtocol.handler = { req in
            if let body = req.httpBody {
                capturedBody = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
            }
            return try mockResponse(statusCode: 200, json: [
                "id": "chatcmpl-3",
                "object": "chat.completion",
                "model": "gpt-4o-mini",
                "choices": [["index": 0, "message": ["role": "assistant", "content": "ok"], "finish_reason": "stop"]],
                "usage": ["prompt_tokens": 5, "completion_tokens": 2, "total_tokens": 7]
            ])
        }

        let provider = OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: "test", model: "gpt-4o-mini", session: .mock)
        _ = try await generateText(model: provider, prompt: "hi", options: GenerationOptions(stopSequences: ["END", "STOP"]))

        XCTAssertEqual(capturedBody?["stop"] as? [String], ["END", "STOP"])
    }

    func testSystemPromptAsFirstMessageForOpenAI() async throws {
        var capturedBody: [String: Any]?
        MockURLProtocol.handler = { req in
            if let body = req.httpBody {
                capturedBody = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
            }
            return try mockResponse(statusCode: 200, json: [
                "id": "chatcmpl-4",
                "object": "chat.completion",
                "model": "gpt-4o-mini",
                "choices": [["index": 0, "message": ["role": "assistant", "content": "ok"], "finish_reason": "stop"]],
                "usage": ["prompt_tokens": 5, "completion_tokens": 2, "total_tokens": 7]
            ])
        }

        let provider = OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: "test", model: "gpt-4o-mini", session: .mock)
        _ = try await generateText(model: provider, prompt: "hi", options: GenerationOptions(system: "Be helpful."))

        let messages = capturedBody?["messages"] as? [[String: String]]
        XCTAssertEqual(messages?.first?["role"], "system")
        XCTAssertEqual(messages?.first?["content"], "Be helpful.")
    }

    func testTopKNotIncludedForOpenAI() async throws {
        var capturedBody: [String: Any]?
        MockURLProtocol.handler = { req in
            if let body = req.httpBody {
                capturedBody = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
            }
            return try mockResponse(statusCode: 200, json: [
                "id": "chatcmpl-5",
                "object": "chat.completion",
                "model": "gpt-4o-mini",
                "choices": [["index": 0, "message": ["role": "assistant", "content": "ok"], "finish_reason": "stop"]],
                "usage": ["prompt_tokens": 5, "completion_tokens": 2, "total_tokens": 7]
            ])
        }

        let provider = OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: "test", model: "gpt-4o-mini", session: .mock)
        _ = try await generateText(model: provider, prompt: "hi", options: GenerationOptions(topK: 40))

        // OpenAI doesn't support topK — must not appear in request body
        XCTAssertNil(capturedBody?["top_k"])
    }

    func testDefaultOptionsProducesNoExtraKeys() async throws {
        var capturedBody: [String: Any]?
        MockURLProtocol.handler = { req in
            if let body = req.httpBody {
                capturedBody = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
            }
            return try mockResponse(statusCode: 200, json: [
                "id": "chatcmpl-6",
                "object": "chat.completion",
                "model": "gpt-4o-mini",
                "choices": [["index": 0, "message": ["role": "assistant", "content": "ok"], "finish_reason": "stop"]],
                "usage": ["prompt_tokens": 5, "completion_tokens": 2, "total_tokens": 7]
            ])
        }

        let provider = OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: "test", model: "gpt-4o-mini", session: .mock)
        _ = try await generateText(model: provider, prompt: "hi")

        // With default (empty) options, optional params must not appear
        XCTAssertNil(capturedBody?["temperature"])
        XCTAssertNil(capturedBody?["max_tokens"])
        XCTAssertNil(capturedBody?["stop"])
        XCTAssertNil(capturedBody?["seed"])
    }

    func testTopPSeedAndPenaltiesForwardedToOpenAI() async throws {
        var capturedBody: [String: Any]?
        MockURLProtocol.handler = { req in
            if let body = req.httpBody {
                capturedBody = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
            }
            return try mockResponse(statusCode: 200, json: [
                "id": "chatcmpl-7",
                "object": "chat.completion",
                "model": "gpt-4o-mini",
                "choices": [["index": 0, "message": ["role": "assistant", "content": "ok"], "finish_reason": "stop"]]
            ])
        }

        let provider = OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: "test", model: "gpt-4o-mini", session: .mock)
        _ = try await generateText(
            model: provider,
            prompt: "hi",
            options: GenerationOptions(topP: 0.8, seed: 42, presencePenalty: 0.2, frequencyPenalty: 0.4)
        )

        XCTAssertEqual(capturedBody?["top_p"] as? Double, 0.8)
        XCTAssertEqual(capturedBody?["seed"] as? Int, 42)
        XCTAssertEqual(capturedBody?["presence_penalty"] as? Double, 0.2)
        XCTAssertEqual(capturedBody?["frequency_penalty"] as? Double, 0.4)
    }

    func testPromptCachingIsNotSerializedForNormalOpenAIGenerateText() async throws {
        var capturedBody: [String: Any]?
        MockURLProtocol.handler = { req in
            if let body = req.httpBody {
                capturedBody = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
            }
            return try mockResponse(statusCode: 200, json: [
                "id": "chatcmpl-8",
                "object": "chat.completion",
                "model": "gpt-4o-mini",
                "choices": [["index": 0, "message": ["role": "assistant", "content": "ok"], "finish_reason": "stop"]]
            ])
        }

        let provider = OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: "test", model: "gpt-4o-mini", session: .mock)
        _ = try await generateText(
            model: provider,
            prompt: "hi",
            options: GenerationOptions(promptCaching: .init(cacheKey: "manual", retention: "ephemeral", cachedContent: "cached"))
        )

        XCTAssertNil(capturedBody?["prompt_cache_key"])
        XCTAssertNil(capturedBody?["prompt_cache_retention"])
        XCTAssertNil(capturedBody?["cached_content"])
    }

    func testPromptCachingIsNotSerializedForNormalOpenAIStreamText() async throws {
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

        let provider = OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: "test", model: "gpt-4o-mini", session: .mock)
        for try await _ in streamText(
            model: provider,
            prompt: "hi",
            options: GenerationOptions(promptCaching: .init(cacheKey: "manual", retention: "ephemeral"))
        ) {}

        XCTAssertNil(capturedBody?["prompt_cache_key"])
        XCTAssertNil(capturedBody?["prompt_cache_retention"])
    }

    // MARK: - Anthropic

    func testTemperatureForwardedToAnthropic() async throws {
        var capturedBody: [String: Any]?
        MockURLProtocol.handler = { req in
            if let body = req.httpBody {
                capturedBody = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
            }
            return try mockResponse(statusCode: 200, json: [
                "id": "msg-1",
                "type": "message",
                "role": "assistant",
                "model": "claude-haiku-4-5-20251001",
                "content": [["type": "text", "text": "ok"]],
                "stop_reason": "end_turn",
                "usage": ["input_tokens": 5, "output_tokens": 2]
            ])
        }

        let provider = AnthropicProvider(apiKey: "test", model: "claude-haiku-4-5-20251001", session: .mock)
        _ = try await generateText(model: provider, prompt: "hi", options: GenerationOptions(temperature: 0.7))

        XCTAssertEqual(capturedBody?["temperature"] as? Double, 0.7)
    }

    func testTopKForwardedToAnthropic() async throws {
        var capturedBody: [String: Any]?
        MockURLProtocol.handler = { req in
            if let body = req.httpBody {
                capturedBody = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
            }
            return try mockResponse(statusCode: 200, json: [
                "id": "msg-2",
                "type": "message",
                "role": "assistant",
                "model": "claude-haiku-4-5-20251001",
                "content": [["type": "text", "text": "ok"]],
                "stop_reason": "end_turn",
                "usage": ["input_tokens": 5, "output_tokens": 2]
            ])
        }

        let provider = AnthropicProvider(apiKey: "test", model: "claude-haiku-4-5-20251001", session: .mock)
        _ = try await generateText(model: provider, prompt: "hi", options: GenerationOptions(topK: 50))

        XCTAssertEqual(capturedBody?["top_k"] as? Int, 50)
    }

    func testSystemPromptTopLevelForAnthropic() async throws {
        var capturedBody: [String: Any]?
        MockURLProtocol.handler = { req in
            if let body = req.httpBody {
                capturedBody = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
            }
            return try mockResponse(statusCode: 200, json: [
                "id": "msg-3",
                "type": "message",
                "role": "assistant",
                "model": "claude-haiku-4-5-20251001",
                "content": [["type": "text", "text": "ok"]],
                "stop_reason": "end_turn",
                "usage": ["input_tokens": 5, "output_tokens": 2]
            ])
        }

        let provider = AnthropicProvider(apiKey: "test", model: "claude-haiku-4-5-20251001", session: .mock)
        _ = try await generateText(model: provider, prompt: "hi", options: GenerationOptions(system: "You are helpful."))

        // Anthropic expects system as top-level field
        XCTAssertEqual(capturedBody?["system"] as? String, "You are helpful.")
        // And system must NOT appear inside messages array
        let messages = capturedBody?["messages"] as? [[String: String]]
        XCTAssertFalse(messages?.contains(where: { $0["role"] == "system" }) ?? false)
    }

    func testMaxTokensOverridesAnthropicDefault() async throws {
        var capturedBody: [String: Any]?
        MockURLProtocol.handler = { req in
            if let body = req.httpBody {
                capturedBody = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
            }
            return try mockResponse(statusCode: 200, json: [
                "id": "msg-4",
                "type": "message",
                "role": "assistant",
                "model": "claude-haiku-4-5-20251001",
                "content": [["type": "text", "text": "ok"]],
                "stop_reason": "end_turn",
                "usage": ["input_tokens": 5, "output_tokens": 2]
            ])
        }

        let provider = AnthropicProvider(apiKey: "test", model: "claude-haiku-4-5-20251001", session: .mock)
        _ = try await generateText(model: provider, prompt: "hi", options: GenerationOptions(maxTokens: 512))

        XCTAssertEqual(capturedBody?["max_tokens"] as? Int, 512)
    }

    // MARK: - Gemini

    func testTemperatureForwardedToGemini() async throws {
        var capturedBody: [String: Any]?
        MockURLProtocol.handler = { req in
            if let body = req.httpBody {
                capturedBody = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
            }
            return try mockResponse(statusCode: 200, json: [
                "candidates": [["content": ["parts": [["text": "ok"]]], "finishReason": "STOP"]],
                "usageMetadata": ["promptTokenCount": 5, "candidatesTokenCount": 2]
            ])
        }

        let provider = GeminiProvider(apiKey: "test", model: "gemini-2.5-flash", session: .mock)
        _ = try await generateText(model: provider, prompt: "hi", options: GenerationOptions(temperature: 0.5))

        let config = capturedBody?["generationConfig"] as? [String: Any]
        XCTAssertEqual(config?["temperature"] as? Double, 0.5)
    }

    func testSystemInstructionForGemini() async throws {
        var capturedBody: [String: Any]?
        MockURLProtocol.handler = { req in
            if let body = req.httpBody {
                capturedBody = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
            }
            return try mockResponse(statusCode: 200, json: [
                "candidates": [["content": ["parts": [["text": "ok"]]], "finishReason": "STOP"]],
                "usageMetadata": ["promptTokenCount": 5, "candidatesTokenCount": 2]
            ])
        }

        let provider = GeminiProvider(apiKey: "test", model: "gemini-2.5-flash", session: .mock)
        _ = try await generateText(model: provider, prompt: "hi", options: GenerationOptions(system: "Be concise."))

        let instruction = capturedBody?["system_instruction"] as? [String: Any]
        let parts = instruction?["parts"] as? [[String: String]]
        XCTAssertEqual(parts?.first?["text"], "Be concise.")
    }

    func testNoGenerationConfigWhenOptionsEmpty() async throws {
        var capturedBody: [String: Any]?
        MockURLProtocol.handler = { req in
            if let body = req.httpBody {
                capturedBody = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
            }
            return try mockResponse(statusCode: 200, json: [
                "candidates": [["content": ["parts": [["text": "ok"]]], "finishReason": "STOP"]],
                "usageMetadata": ["promptTokenCount": 5, "candidatesTokenCount": 2]
            ])
        }

        let provider = GeminiProvider(apiKey: "test", model: "gemini-2.5-flash", session: .mock)
        _ = try await generateText(model: provider, prompt: "hi")

        XCTAssertNil(capturedBody?["generationConfig"])
    }

    // MARK: - Callbacks

    func testOnChunkCalledForEveryChunk() async throws {
        MockURLProtocol.handler = { _ in
            try mockSSEResponse(chunks: [
                ["id": "1", "object": "chat.completion.chunk", "model": "gpt-4o-mini", "choices": [["index": 0, "delta": ["content": "Hello"], "finish_reason": NSNull()]]],
                ["id": "2", "object": "chat.completion.chunk", "model": "gpt-4o-mini", "choices": [["index": 0, "delta": ["content": " world"], "finish_reason": NSNull()]]],
                ["id": "3", "object": "chat.completion.chunk", "model": "gpt-4o-mini", "choices": [["index": 0, "delta": [:], "finish_reason": "stop"]]]
            ])
        }

        let provider = OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: "test", model: "gpt-4o-mini", session: .mock)

        var chunkTexts: [String] = []
        for try await _ in streamText(model: provider, prompt: "hi", onChunk: { chunk in
            if !chunk.text.isEmpty { chunkTexts.append(chunk.text) }
        }) {}

        XCTAssertEqual(chunkTexts, ["Hello", " world"])
    }

    func testOnFinishCalledOnceWithFullText() async throws {
        MockURLProtocol.handler = { _ in
            try mockSSEResponse(chunks: [
                ["id": "1", "object": "chat.completion.chunk", "model": "gpt-4o-mini", "choices": [["index": 0, "delta": ["content": "Hello"], "finish_reason": NSNull()]]],
                ["id": "2", "object": "chat.completion.chunk", "model": "gpt-4o-mini", "choices": [["index": 0, "delta": ["content": " world"], "finish_reason": NSNull()]]],
                ["id": "3", "object": "chat.completion.chunk", "model": "gpt-4o-mini", "choices": [["index": 0, "delta": [:], "finish_reason": "stop"]]]
            ])
        }

        let provider = OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: "test", model: "gpt-4o-mini", session: .mock)

        var finishCallCount = 0
        var finishResponse: AIResponse?
        for try await _ in streamText(model: provider, prompt: "hi", onFinish: { response in
            finishCallCount += 1
            finishResponse = response
        }) {}

        XCTAssertEqual(finishCallCount, 1)
        XCTAssertEqual(finishResponse?.text, "Hello world")
    }

    func testOnChunkAndOnFinishBothFire() async throws {
        MockURLProtocol.handler = { _ in
            try mockSSEResponse(chunks: [
                ["id": "1", "object": "chat.completion.chunk", "model": "gpt-4o-mini", "choices": [["index": 0, "delta": ["content": "Hi"], "finish_reason": NSNull()]]],
                ["id": "2", "object": "chat.completion.chunk", "model": "gpt-4o-mini", "choices": [["index": 0, "delta": [:], "finish_reason": "stop"]]]
            ])
        }

        let provider = OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: "test", model: "gpt-4o-mini", session: .mock)

        var chunkFired = false
        var finishFired = false
        for try await _ in streamText(
            model: provider,
            prompt: "hi",
            onChunk: { _ in chunkFired = true },
            onFinish: { _ in finishFired = true }
        ) {}

        XCTAssertTrue(chunkFired)
        XCTAssertTrue(finishFired)
    }

    func testRetryPolicyExponentialBackoffSequence() {
        let policy = RetryPolicy(
            maxAttempts: 5,
            baseDelay: .milliseconds(250),
            maxDelay: .seconds(30),
            jitter: 0
        )
        XCTAssertEqual(policy.delay(forAttempt: 1), .milliseconds(250))
        XCTAssertEqual(policy.delay(forAttempt: 2), .milliseconds(500))
        XCTAssertEqual(policy.delay(forAttempt: 3), .milliseconds(1000))
        XCTAssertEqual(policy.delay(forAttempt: 4), .milliseconds(2000))
    }

    func testRetryPolicyCappedByMaxDelay() {
        let policy = RetryPolicy(
            maxAttempts: 10,
            baseDelay: .milliseconds(250),
            maxDelay: .milliseconds(750),
            jitter: 0
        )
        XCTAssertEqual(policy.delay(forAttempt: 1), .milliseconds(250))
        XCTAssertEqual(policy.delay(forAttempt: 2), .milliseconds(500))
        // 1000ms exceeds 750ms cap
        XCTAssertEqual(policy.delay(forAttempt: 3), .milliseconds(750))
        XCTAssertEqual(policy.delay(forAttempt: 7), .milliseconds(750))
    }

    func testRetryPolicyJitterWithinBounds() {
        let policy = RetryPolicy(
            maxAttempts: 3,
            baseDelay: .milliseconds(100),
            maxDelay: .seconds(30),
            jitter: 0.5
        )
        // attempt 1: nominal 100ms, jitter ±50% → range [50ms, 150ms]
        for _ in 0..<20 {
            let d = policy.delay(forAttempt: 1)
            let nanos = d.components.seconds * 1_000_000_000 + d.components.attoseconds / 1_000_000_000
            XCTAssertGreaterThanOrEqual(nanos, 50_000_000)
            XCTAssertLessThanOrEqual(nanos, 150_000_000)
        }
    }
}
