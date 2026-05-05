import Foundation
import Observation
import SwiftyAI

enum EmbeddingExampleDefaults {
    static func defaultModel(for provider: AIProvider) -> String? {
        switch provider {
        case .openAI:
            "text-embedding-3-small"
        case .gemini:
            "gemini-embedding-001"
        default:
            nil
        }
    }

    static func modelLabel(settings: ProviderSettings, customModel: String) -> String {
        guard defaultModel(for: settings.provider) != nil else {
            return "Choose OpenAI or Gemini in Settings"
        }

        let custom = trimmed(customModel)
        if !custom.isEmpty {
            return "\(settings.provider.displayName): \(custom)"
        }

        return "\(settings.provider.displayName): \(defaultModel(for: settings.provider) ?? "")"
    }

    static func makeModel(
        settings: ProviderSettings,
        apiKey: String,
        customModel: String
    ) throws -> any AIEmbeddingModel {
        let model = try resolvedModel(settings: settings, customModel: customModel)
        let embeddingSettings = ProviderSettings(
            provider: settings.provider,
            model: model,
            accountID: settings.accountID,
            ollamaBaseURL: settings.ollamaBaseURL
        )
        try ModelFactory.validate(settings: embeddingSettings, apiKey: apiKey)

        switch settings.provider {
        case .openAI:
            return OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: apiKey, model: model)
        case .gemini:
            return GeminiProvider(apiKey: apiKey, model: model)
        default:
            throw ExampleError.message("The embeddings example supports OpenAI and Gemini settings.")
        }
    }

    static func queryOptions(for provider: AIProvider) -> EmbeddingOptions {
        provider == .gemini ? EmbeddingOptions(taskType: .retrievalQuery) : EmbeddingOptions()
    }

    static func documentOptions(for provider: AIProvider) -> EmbeddingOptions {
        provider == .gemini
            ? EmbeddingOptions(taskType: .retrievalDocument, title: "SwiftyAI example documents")
            : EmbeddingOptions()
    }

    static func resolvedModel(settings: ProviderSettings, customModel: String) throws -> String {
        guard defaultModel(for: settings.provider) != nil else {
            throw ExampleError.message("The embeddings example supports OpenAI and Gemini settings.")
        }

        let custom = trimmed(customModel)
        if !custom.isEmpty {
            return custom
        }

        return defaultModel(for: settings.provider) ?? ""
    }

    private static func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct EmbeddingSearchResult: Identifiable, Equatable {
    let id: Int
    let document: String
    let score: Double
}

@MainActor
@Observable
final class EmbeddingsExampleViewModel {
    var query = "How does Swift protect shared mutable state?"
    var documentsText = """
    Swift actors isolate mutable state.
    Structured concurrency scopes child tasks.
    SwiftUI observation updates views when state changes.
    """
    var customModel = ""
    var results: [EmbeddingSearchResult] = []
    var vectorDimensions: Int?
    var inputTokens: Int?
    var modelName: String?
    var state: ExampleState<Void> = .idle

    func run(settings: ProviderSettings, apiKey: String) async {
        state = .loading
        results = []
        vectorDimensions = nil
        inputTokens = nil
        modelName = nil

        do {
            let queryText = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !queryText.isEmpty else {
                throw ExampleError.message("Enter a query before comparing embeddings.")
            }

            let documents = Self.parseDocuments(documentsText)
            guard !documents.isEmpty else {
                throw ExampleError.message("Enter at least one document, one per line.")
            }

            let model = try EmbeddingExampleDefaults.makeModel(
                settings: settings,
                apiKey: apiKey,
                customModel: customModel
            )
            modelName = try EmbeddingExampleDefaults.resolvedModel(settings: settings, customModel: customModel)

            let queryResponse = try await embed(
                model: model,
                input: queryText,
                options: EmbeddingExampleDefaults.queryOptions(for: settings.provider)
            )
            let documentResponse = try await embedMany(
                model: model,
                inputs: documents,
                options: EmbeddingExampleDefaults.documentOptions(for: settings.provider)
            )

            guard let queryVector = queryResponse.embedding, !queryVector.isEmpty else {
                throw ExampleError.message("The provider returned an empty query embedding.")
            }

            results = Self.rankDocuments(
                queryVector: queryVector,
                documents: documents,
                documentVectors: documentResponse.embeddings
            )
            vectorDimensions = queryVector.count
            inputTokens = Self.totalInputTokens(queryResponse.usage, documentResponse.usage)
            state = .success(())
        } catch {
            state = .failure(error.exampleMessage)
        }
    }

    static func parseDocuments(_ text: String) -> [String] {
        text
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    static func rankDocuments(
        queryVector: [Double],
        documents: [String],
        documentVectors: [[Double]]
    ) -> [EmbeddingSearchResult] {
        zip(documents.indices, zip(documents, documentVectors))
            .map { index, pair in
                EmbeddingSearchResult(
                    id: index,
                    document: pair.0,
                    score: cosineSimilarity(queryVector, pair.1)
                )
            }
            .sorted { $0.score > $1.score }
    }

    private static func totalInputTokens(_ lhs: EmbeddingUsage?, _ rhs: EmbeddingUsage?) -> Int? {
        guard lhs != nil || rhs != nil else { return nil }
        return (lhs?.inputTokens ?? 0) + (rhs?.inputTokens ?? 0)
    }
}
