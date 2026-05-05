import XCTest
import SwiftyAI

final class EmbeddingPackageTests: XCTestCase {
    func testEmbeddingPublicAPIExports() async throws {
        let model = CapturingEmbeddingModel()

        let single = try await embed(
            model: model,
            input: "Swift concurrency",
            options: EmbeddingOptions(dimensions: 2)
        )
        let batch = try await embedMany(model: model, inputs: ["first", "second"])

        XCTAssertEqual(model.capturedInputs, ["first", "second"])
        XCTAssertEqual(single.embedding ?? [], [1, 0])
        XCTAssertEqual(batch.embeddings.count, 2)
        XCTAssertEqual(cosineSimilarity(single.embeddings[0], [1, 0]), 1, accuracy: 0.000001)
    }

    func testProviderTypesConformToEmbeddingModel() {
        let openAI = OpenAICompatibleProvider(
            baseURL: "https://api.openai.com/v1",
            apiKey: "key",
            model: "text-embedding-3-small"
        )
        let gemini = GeminiProvider(apiKey: "key", model: "gemini-embedding-001")
        let models: [any AIEmbeddingModel] = [openAI, gemini]

        XCTAssertEqual(models.count, 2)
    }
}

private final class CapturingEmbeddingModel: AIEmbeddingModel, @unchecked Sendable {
    private(set) var capturedInputs: [String]?

    func embed(_ input: String, options: EmbeddingOptions) async throws -> EmbeddingResponse {
        capturedInputs = [input]
        return EmbeddingResponse(
            embeddings: [[1, 0]],
            model: "mock-embedding",
            usage: EmbeddingUsage(inputTokens: 2, totalTokens: 2)
        )
    }

    func embedMany(_ inputs: [String], options: EmbeddingOptions) async throws -> EmbeddingResponse {
        capturedInputs = inputs
        return EmbeddingResponse(
            embeddings: inputs.map { _ in [1, 0] },
            model: "mock-embedding"
        )
    }
}
