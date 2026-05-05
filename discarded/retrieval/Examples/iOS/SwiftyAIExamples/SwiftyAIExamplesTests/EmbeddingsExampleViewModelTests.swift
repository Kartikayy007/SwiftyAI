import XCTest
@testable import SwiftyAIExamples

final class EmbeddingsExampleViewModelTests: XCTestCase {
    @MainActor
    func testParseDocumentsTrimsBlankLines() {
        let documents = EmbeddingsExampleViewModel.parseDocuments("""

          Swift actors isolate mutable state.

          Structured concurrency scopes child tasks.
        """)

        XCTAssertEqual(documents, [
            "Swift actors isolate mutable state.",
            "Structured concurrency scopes child tasks."
        ])
    }

    @MainActor
    func testRankDocumentsSortsByCosineSimilarity() {
        let results = EmbeddingsExampleViewModel.rankDocuments(
            queryVector: [1, 0],
            documents: ["unrelated", "exact", "close"],
            documentVectors: [
                [0, 1],
                [1, 0],
                [0.8, 0.2]
            ]
        )

        XCTAssertEqual(results.map(\.document), ["exact", "close", "unrelated"])
        XCTAssertEqual(results.first?.score, 1, accuracy: 0.0001)
    }

    func testEmbeddingDefaultsStaySmall() {
        XCTAssertEqual(EmbeddingExampleDefaults.defaultModel(for: .openAI), "text-embedding-3-small")
        XCTAssertEqual(EmbeddingExampleDefaults.defaultModel(for: .gemini), "gemini-embedding-001")
        XCTAssertNil(EmbeddingExampleDefaults.defaultModel(for: .anthropic))
    }

    func testUnsupportedProviderDoesNotResolveCustomModel() {
        XCTAssertThrowsError(
            try EmbeddingExampleDefaults.resolvedModel(
                settings: ProviderSettings(provider: .anthropic, model: "claude-3-5-haiku-latest"),
                customModel: "custom-embedding-model"
            )
        )
    }
}
