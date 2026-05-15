public protocol AIEmbeddingModel: Sendable {
    func embed(_ input: String, options: EmbeddingOptions) async throws -> EmbeddingResponse
    func embedMany(_ inputs: [String], options: EmbeddingOptions) async throws -> EmbeddingResponse
}

public extension AIEmbeddingModel {
    func embed(_ input: String) async throws -> EmbeddingResponse {
        try await embed(input, options: EmbeddingOptions())
    }

    func embedMany(_ inputs: [String]) async throws -> EmbeddingResponse {
        try await embedMany(inputs, options: EmbeddingOptions())
    }
}

public extension AIEmbeddingModel where Self == OpenAICompatibleProvider {
    static func openAI(apiKey: String, model: String) -> OpenAICompatibleProvider {
        OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: apiKey, model: model)
    }

    static func openAICompatible(baseURL: String, apiKey: String, model: String) -> OpenAICompatibleProvider {
        OpenAICompatibleProvider(baseURL: baseURL, apiKey: apiKey, model: model)
    }
}

public extension AIEmbeddingModel where Self == GeminiProvider {
    static func gemini(apiKey: String, model: String) -> GeminiProvider {
        GeminiProvider(apiKey: apiKey, model: model)
    }
}
