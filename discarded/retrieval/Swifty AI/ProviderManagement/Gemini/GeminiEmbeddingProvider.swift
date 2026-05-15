import Foundation

extension GeminiProvider: AIEmbeddingModel {
    public func embed(_ input: String, options: EmbeddingOptions) async throws -> EmbeddingResponse {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/\(embeddingModelResource):embedContent") else {
            throw AIError.invalidResponse
        }

        let body = GeminiEmbeddingRequest(
            model: embeddingModelResource,
            content: .init(text: input),
            taskType: options.taskType?.rawValue,
            title: options.geminiTitle,
            outputDimensionality: options.dimensions
        )
        let data = try await httpPost(
            url: url,
            headers: ["x-goog-api-key": apiKey],
            body: body,
            session: session,
            options: options.generationOptions
        )

        do {
            let decoded = try JSONDecoder().decode(GeminiSingleEmbeddingResponse.self, from: data)
            guard !decoded.embedding.values.isEmpty else {
                throw AIError.invalidResponse
            }
            return EmbeddingResponse(
                embeddings: [decoded.embedding.values],
                model: model,
                usage: decoded.usageMetadata?.embeddingUsage
            )
        } catch let error as AIError {
            throw error
        } catch {
            throw AIError.decodingError(error)
        }
    }

    public func embedMany(_ inputs: [String], options: EmbeddingOptions) async throws -> EmbeddingResponse {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/\(embeddingModelResource):batchEmbedContents") else {
            throw AIError.invalidResponse
        }

        let body = GeminiBatchEmbeddingRequest(
            requests: inputs.map {
                GeminiEmbeddingRequest(
                    model: embeddingModelResource,
                    content: .init(text: $0),
                    taskType: options.taskType?.rawValue,
                    title: options.geminiTitle,
                    outputDimensionality: options.dimensions
                )
            }
        )
        let data = try await httpPost(
            url: url,
            headers: ["x-goog-api-key": apiKey],
            body: body,
            session: session,
            options: options.generationOptions
        )

        do {
            let decoded = try JSONDecoder().decode(GeminiBatchEmbeddingResponse.self, from: data)
            let embeddings = decoded.embeddings.map(\.values)
            guard !embeddings.isEmpty, embeddings.allSatisfy({ !$0.isEmpty }) else {
                throw AIError.invalidResponse
            }
            return EmbeddingResponse(
                embeddings: embeddings,
                model: model,
                usage: decoded.usageMetadata?.embeddingUsage
            )
        } catch let error as AIError {
            throw error
        } catch {
            throw AIError.decodingError(error)
        }
    }

    private var embeddingModelResource: String {
        model.hasPrefix("models/") ? model : "models/\(model)"
    }
}

private extension EmbeddingOptions {
    var geminiTitle: String? {
        taskType == .retrievalDocument ? title : nil
    }
}

private struct GeminiEmbeddingRequest: Encodable {
    let model: String
    let content: Content
    let taskType: String?
    let title: String?
    let outputDimensionality: Int?

    struct Content: Encodable {
        let parts: [Part]

        init(text: String) {
            self.parts = [.init(text: text)]
        }

        struct Part: Encodable {
            let text: String
        }
    }
}

private struct GeminiBatchEmbeddingRequest: Encodable {
    let requests: [GeminiEmbeddingRequest]
}

private struct GeminiSingleEmbeddingResponse: Decodable {
    let embedding: GeminiContentEmbedding
    let usageMetadata: GeminiEmbeddingUsageMetadata?
}

private struct GeminiBatchEmbeddingResponse: Decodable {
    let embeddings: [GeminiContentEmbedding]
    let usageMetadata: GeminiEmbeddingUsageMetadata?
}

private struct GeminiContentEmbedding: Decodable {
    let values: [Double]
}

private struct GeminiEmbeddingUsageMetadata: Decodable {
    let promptTokenCount: Int?
    let inputTokenCount: Int?
    let totalTokenCount: Int?

    var embeddingUsage: EmbeddingUsage? {
        guard let inputTokens = promptTokenCount ?? inputTokenCount ?? totalTokenCount else {
            return nil
        }
        return EmbeddingUsage(inputTokens: inputTokens, totalTokens: totalTokenCount)
    }
}
