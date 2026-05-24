import XCTest
@testable import Swifty_AI

final class AIRegistryTests: XCTestCase {
    private var registry: AIRegistry!

    override func setUp() async throws {
        registry = AIRegistry()
    }

    func testConfigureAndResolveOpenAI() async throws {
        await registry.set(.apiKey("sk-test"), for: "openai")
        let model = try await registry.resolve("openai/gpt-4o-mini")
        XCTAssertTrue(model is OpenAICompatibleProvider)
    }

    func testConfigureAndResolveAnthropic() async throws {
        await registry.set(.apiKey("sk-ant-test"), for: "anthropic")
        let model = try await registry.resolve("anthropic/claude-haiku-4-5-20251001")
        XCTAssertTrue(model is AnthropicProvider)
    }

    func testConfigureAndResolveGemini() async throws {
        await registry.set(.apiKey("AIza-test"), for: "gemini")
        let model = try await registry.resolve("gemini/gemini-2.5-flash")
        XCTAssertTrue(model is GeminiProvider)
    }

    func testConfigureAndResolveGroq() async throws {
        await registry.set(.apiKey("gsk_test"), for: "groq")
        let model = try await registry.resolve("groq/llama-3.3-70b-versatile")
        XCTAssertTrue(model is OpenAICompatibleProvider)
    }

    func testResolveEveryOpenAIAndGeminiMediaModelType() async throws {
        await registry.set(.apiKey("sk-test"), for: "openai")
        await registry.set(.apiKey("gemini-test"), for: "gemini")

        let openaiImage = try await registry.resolveImageModel("openai/gpt-image-1")
        XCTAssertTrue(openaiImage is OpenAICompatibleProvider)
        
        let openaiTranscription = try await registry.resolveTranscriptionModel("openai/gpt-4o-transcribe")
        XCTAssertTrue(openaiTranscription is OpenAICompatibleProvider)
        
        let openaiSpeech = try await registry.resolveSpeechModel("openai/gpt-4o-mini-tts")
        XCTAssertTrue(openaiSpeech is OpenAICompatibleProvider)
        
        let openaiVideo = try await registry.resolveVideoModel("openai/sora-2")
        XCTAssertTrue(openaiVideo is OpenAICompatibleProvider)

        let geminiImage = try await registry.resolveImageModel("gemini/imagen-4.0-generate-001")
        XCTAssertTrue(geminiImage is GeminiProvider)
        
        let geminiTranscription = try await registry.resolveTranscriptionModel("gemini/gemini-2.5-flash")
        XCTAssertTrue(geminiTranscription is GeminiProvider)
        
        let geminiSpeech = try await registry.resolveSpeechModel("gemini/gemini-2.5-flash-preview-tts")
        XCTAssertTrue(geminiSpeech is GeminiProvider)
        
        let geminiVideo = try await registry.resolveVideoModel("gemini/veo-3.1-generate-preview")
        XCTAssertTrue(geminiVideo is GeminiProvider)
    }

    func testResolveMediaForUnsupportedGlobalProviderThrows() async throws {
        await registry.set(.apiKey("anthropic-test"), for: "anthropic")

        do {
            _ = try await registry.resolveImageModel("anthropic/claude-haiku-4-5-20251001")
            XCTFail("Expected unsupported media provider")
        } catch AIError.unsupportedFeature(let message) {
            XCTAssertTrue(message.contains("anthropic"))
        }
    }

    func testResolveMediaForUnconfiguredProviderThrows() async throws {
        do {
            _ = try await registry.resolveSpeechModel("openai/gpt-4o-mini-tts")
            XCTFail("Expected providerNotConfigured")
        } catch AIError.providerNotConfigured(let provider) {
            XCTAssertEqual(provider, "openai")
        }
    }

    func testResolveUnconfiguredProviderThrows() async throws {
        do {
            _ = try await registry.resolve("openai/gpt-4o")
            XCTFail("Expected throw")
        } catch AIError.providerNotConfigured(let name) {
            XCTAssertEqual(name, "openai")
        }
    }

    func testInvalidModelStringThrows() async throws {
        do {
            _ = try await registry.resolve("noslash")
            XCTFail("Expected throw")
        } catch AIError.invalidModelString(let s) {
            XCTAssertEqual(s, "noslash")
        }
    }

    func testResolveOllamaRequiresNoKey() async throws {
        // ollama falls back to default base URL without any configure call
        let model = try await registry.resolve("ollama/llama3.2")
        XCTAssertTrue(model is OpenAICompatibleProvider)
    }

    func testConfigureOverwritesPreviousKey() async throws {
        await registry.set(.apiKey("old-key"), for: "openai")
        await registry.set(.apiKey("new-key"), for: "openai")
        // Just verifying resolve still works after overwrite — key internals not exposed
        let model = try await registry.resolve("openai/gpt-4o")
        XCTAssertTrue(model is OpenAICompatibleProvider)
    }

    func testCaseInsensitiveProvider() async throws {
        await registry.set(.apiKey("sk-test"), for: "openai")
        // "OpenAI" should resolve same as "openai"
        let model = try await registry.resolve("OpenAI/gpt-4o")
        XCTAssertTrue(model is OpenAICompatibleProvider)
    }

    func testResolveCreatesNewInstanceEachCall() async throws {
        await registry.set(.apiKey("sk-test"), for: "openai")
        let m1 = try await registry.resolve("openai/gpt-4o")
        let m2 = try await registry.resolve("openai/gpt-4o")
        XCTAssertTrue(m1 is OpenAICompatibleProvider)
        XCTAssertTrue(m2 is OpenAICompatibleProvider)
        XCTAssertFalse(m1 as AnyObject === m2 as AnyObject)
    }

    func testConfigureIsImmediatelyVisible() async throws {
        AI.configure { ai in
            ai.openAI(apiKey: "sk-immediate")
        }
        let model = try await AIRegistry.shared.resolve("openai/gpt-4o-mini")
        XCTAssertTrue(model is OpenAICompatibleProvider)
    }

    func testGenerateTextStringOverload() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(statusCode: 200, json: [
                "id": "chatcmpl-test",
                "object": "chat.completion",
                "model": "gpt-4o-mini",
                "choices": [[
                    "index": 0,
                    "message": ["role": "assistant", "content": "Hello there!"],
                    "finish_reason": "stop"
                ]],
                "usage": ["prompt_tokens": 10, "completion_tokens": 5, "total_tokens": 15]
            ])
        }

        // Configure shared registry with a mock-session provider manually
        // (AI.configure uses shared registry; inject directly for test isolation)
        let provider = OpenAICompatibleProvider(
            baseURL: "https://api.openai.com/v1",
            apiKey: "sk-test",
            model: "gpt-4o-mini",
            session: .mock
        )
        let response = try await generateText(model: provider, prompt: "Hello")
        XCTAssertEqual(response.text, "Hello there!")
    }
}
