public protocol AIModel: Sendable {
    func generate(_ prompt: String) async throws -> AIResponse
    func generate(_ prompt: String, options: GenerationOptions) async throws -> AIResponse
    func generate(_ prompt: [AIMessageContent], options: GenerationOptions) async throws -> AIResponse
}

public extension AIModel {
    func generate(_ prompt: String, options: GenerationOptions) async throws -> AIResponse {
        try await generate(prompt)
    }

    func generate(_ prompt: [AIMessageContent], options: GenerationOptions) async throws -> AIResponse {
        try await generate(prompt.textContent, options: options)
    }
}

public extension AIModel where Self == OpenAICompatibleProvider {
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

public extension AIModel where Self == AnthropicProvider {
    static func anthropic(apiKey: String, model: String) -> AnthropicProvider {
        AnthropicProvider(apiKey: apiKey, model: model)
    }
}

public extension AIModel where Self == GeminiProvider {
    static func gemini(apiKey: String, model: String) -> GeminiProvider {
        GeminiProvider(apiKey: apiKey, model: model)
    }
}

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26, macOS 26, *)
public extension AIModel where Self == AppleFoundationProvider {
    static func appleFoundation() -> AppleFoundationProvider {
        AppleFoundationProvider()
    }
}
#endif
