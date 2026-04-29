import XCTest

@testable import Swifty_AI

final class EmbeddingUtilitiesTests: XCTestCase {
    func testCosineSimilarity() {
        XCTAssertEqual(cosineSimilarity([1, 0], [1, 0]), 1, accuracy: 0.000001)
        XCTAssertEqual(cosineSimilarity([1, 0], [0, 1]), 0, accuracy: 0.000001)
        XCTAssertEqual(cosineSimilarity([1, 1], [1, 1]), 1, accuracy: 0.000001)
    }

    func testCosineSimilarityReturnsZeroForInvalidInputs() {
        XCTAssertEqual(cosineSimilarity([], []), 0)
        XCTAssertEqual(cosineSimilarity([1, 2], [1]), 0)
        XCTAssertEqual(cosineSimilarity([0, 0], [1, 2]), 0)
    }

    func testRegistryResolvesEmbeddingModels() async throws {
        let registry = AIRegistry()
        await registry.set(.apiKey("sk-test"), for: "openai")
        await registry.set(.apiKey("AIza-test"), for: "gemini")

        let openAI = try await registry.resolveEmbeddingModel("openai/text-embedding-3-small")
        let gemini = try await registry.resolveEmbeddingModel("gemini/gemini-embedding-001")

        XCTAssertTrue(openAI is OpenAICompatibleProvider)
        XCTAssertTrue(gemini is GeminiProvider)
    }

    func testRegistryRejectsNonEmbeddingProvider() async throws {
        let registry = AIRegistry()
        await registry.set(.apiKey("sk-ant-test"), for: "anthropic")

        do {
            _ = try await registry.resolveEmbeddingModel("anthropic/claude-haiku-4-5-20251001")
            XCTFail("Expected unsupportedFeature")
        } catch AIError.unsupportedFeature(let message) {
            XCTAssertTrue(message.contains("Embeddings"))
        }
    }
}
