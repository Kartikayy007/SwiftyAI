public protocol AIStreamModel: AIModel {
    func stream(_ prompt: String) -> AsyncThrowingStream<AIStreamChunk, Error>
    func stream(_ prompt: String, options: GenerationOptions) -> AsyncThrowingStream<AIStreamChunk, Error>
    func stream(_ prompt: [AIMessageContent], options: GenerationOptions) -> AsyncThrowingStream<AIStreamChunk, Error>
    func stream(messages: [ChatMessage]) -> AsyncThrowingStream<AIStreamChunk, Error>
    func stream(messages: [ChatMessage], options: GenerationOptions) -> AsyncThrowingStream<AIStreamChunk, Error>
}

public extension AIStreamModel {
    func stream(_ prompt: String, options: GenerationOptions) -> AsyncThrowingStream<AIStreamChunk, Error> {
        stream(prompt)
    }

    func stream(_ prompt: [AIMessageContent], options: GenerationOptions) -> AsyncThrowingStream<AIStreamChunk, Error> {
        stream(prompt.textContent, options: options)
    }

    func stream(messages: [ChatMessage]) -> AsyncThrowingStream<AIStreamChunk, Error> {
        stream(messages: messages, options: GenerationOptions())
    }

    /// Default implementation forwards `options` through to the array-prompt variant,
    /// extracting a leading system-role message into `options.system` when not already set.
    /// Providers that need multi-turn-aware bodies should override this directly.
    func stream(messages: [ChatMessage], options: GenerationOptions) -> AsyncThrowingStream<AIStreamChunk, Error> {
        var opts = options
        var working = messages
        if opts.system == nil, let first = working.first, first.role == .system {
            opts.system = first.content
            working.removeFirst()
        }
        // Use the most recent user message's parts to preserve multimodal content.
        let parts = working.last(where: { $0.role == .user })?.parts ?? [.text("")]
        return stream(parts, options: opts)
    }
}

public extension AIStreamModel where Self == OpenAICompatibleProvider {
    static func openAI(apiKey: String, model: String) -> OpenAICompatibleProvider {
        OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: apiKey, model: model)
    }

    static func groq(apiKey: String, model: String) -> OpenAICompatibleProvider {
        OpenAICompatibleProvider(baseURL: "https://api.groq.com/openai/v1", apiKey: apiKey, model: model)
    }

    static func openRouter(apiKey: String, model: String) -> OpenAICompatibleProvider {
        OpenAICompatibleProvider(baseURL: "https://openrouter.ai/api/v1", apiKey: apiKey, model: model)
    }

    static func mistral(apiKey: String, model: String) -> OpenAICompatibleProvider {
        OpenAICompatibleProvider(baseURL: "https://api.mistral.ai/v1", apiKey: apiKey, model: model)
    }

    static func cohere(apiKey: String, model: String) -> OpenAICompatibleProvider {
        OpenAICompatibleProvider(baseURL: "https://api.cohere.com/compatibility/v1", apiKey: apiKey, model: model)
    }

    static func cloudflare(accountID: String, apiKey: String, model: String) -> OpenAICompatibleProvider {
        OpenAICompatibleProvider(baseURL: "https://api.cloudflare.com/client/v4/accounts/\(accountID)/ai/v1", apiKey: apiKey, model: model)
    }

    static func ollama(model: String, baseURL: String = "http://localhost:11434/v1") -> OpenAICompatibleProvider {
        OpenAICompatibleProvider(baseURL: baseURL, apiKey: "ollama", model: model)
    }
}

public extension AIStreamModel where Self == AnthropicProvider {
    static func anthropic(apiKey: String, model: String) -> AnthropicProvider {
        AnthropicProvider(apiKey: apiKey, model: model)
    }
}

public extension AIStreamModel where Self == GeminiProvider {
    static func gemini(apiKey: String, model: String) -> GeminiProvider {
        GeminiProvider(apiKey: apiKey, model: model)
    }
}

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26, macOS 26, *)
public extension AIStreamModel where Self == AppleFoundationProvider {
    static func appleFoundation() -> AppleFoundationProvider {
        AppleFoundationProvider()
    }
}
#endif
