import Foundation

extension OpenAICompatibleProvider: AIEmbeddingModel {
    public func embed(_ input: String, options: EmbeddingOptions) async throws -> EmbeddingResponse {
        try await embed(input: .single(input), options: options)
    }

    public func embedMany(_ inputs: [String], options: EmbeddingOptions) async throws -> EmbeddingResponse {
        try await embed(input: .batch(inputs), options: options)
    }

    private func embed(input: EmbeddingRequestInput, options: EmbeddingOptions) async throws -> EmbeddingResponse {
        guard let url = URL(string: "\(baseURL)/embeddings") else {
            throw AIError.invalidResponse
        }

        let body = OpenAIEmbeddingRequest(
            model: model,
            input: input,
            dimensions: options.dimensions
        )
        let data = try await httpPost(
            url: url,
            headers: ["Authorization": "Bearer \(apiKey)"],
            body: body,
            session: session,
            options: options.generationOptions
        )

        do {
            let decoded = try JSONDecoder().decode(OpenAIEmbeddingResponse.self, from: data)
            let embeddings = decoded.data
                .sorted { $0.index < $1.index }
                .map(\.embedding)
            guard !embeddings.isEmpty else {
                throw AIError.invalidResponse
            }
            let usage = decoded.usage.map {
                EmbeddingUsage(inputTokens: $0.promptTokens, totalTokens: $0.totalTokens)
            }
            return EmbeddingResponse(embeddings: embeddings, model: decoded.model, usage: usage)
        } catch let error as AIError {
            throw error
        } catch {
            throw AIError.decodingError(error)
        }
    }
}

private enum EmbeddingRequestInput: Encodable {
    case single(String)
    case batch([String])

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .single(let input):
            try container.encode(input)
        case .batch(let inputs):
            try container.encode(inputs)
        }
    }
}

private struct OpenAIEmbeddingRequest: Encodable {
    let model: String
    let input: EmbeddingRequestInput
    let dimensions: Int?
    let encodingFormat = "float"

    enum CodingKeys: String, CodingKey {
        case model, input, dimensions
        case encodingFormat = "encoding_format"
    }
}

private struct OpenAIEmbeddingResponse: Decodable {
    let data: [EmbeddingData]
    let model: String?
    let usage: Usage?

    struct EmbeddingData: Decodable {
        let embedding: [Double]
        let index: Int
    }

    struct Usage: Decodable {
        let promptTokens: Int
        let totalTokens: Int?

        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case totalTokens = "total_tokens"
        }
    }
}
