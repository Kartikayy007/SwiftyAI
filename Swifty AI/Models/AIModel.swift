public protocol AIModel: Sendable {
    func generate(_ prompt: String) async throws -> AIResponse
}

public extension AIModel where Self == OpenAIProvider {
    static func openAI(apiKey: String, model: String) -> OpenAIProvider {
        OpenAIProvider(apiKey: apiKey, model: model)
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
