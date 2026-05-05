import XCTest

@testable import Swifty_AI

final class RerankTests: XCTestCase {
    func testRerankUsesCustomModelConformance() async throws {
        let model = CapturingReranker()

        let response = try await rerank(
            model: model,
            query: "capital city",
            documents: ["Washington, D.C.", "Carson City"],
            options: RerankOptions(topN: 1)
        )

        XCTAssertEqual(model.capturedQuery, "capital city")
        XCTAssertEqual(model.capturedDocuments.map(\.text), ["Washington, D.C.", "Carson City"])
        XCTAssertEqual(model.capturedOptions?.topN, 1)
        XCTAssertEqual(response.results.first?.index, 0)
    }

    func testRegistryResolvesCohereRerankModel() async throws {
        let registry = AIRegistry()
        await registry.set(.apiKey("test-key"), for: "cohere")

        let model = try await registry.resolveRerankModel("cohere/rerank-v3.5")

        XCTAssertTrue(model is CohereRerankProvider)
    }

    func testRegistryRejectsUnsupportedRerankProvider() async throws {
        let registry = AIRegistry()
        await registry.set(.apiKey("test-key"), for: "openai")

        do {
            _ = try await registry.resolveRerankModel("openai/gpt-4o-mini")
            XCTFail("Expected unsupportedFeature")
        } catch AIError.unsupportedFeature(let message) {
            XCTAssertTrue(message.contains("openai"))
        }
    }
}

private final class CapturingReranker: AIRerankModel, @unchecked Sendable {
    private(set) var capturedQuery: String?
    private(set) var capturedDocuments: [RerankDocument] = []
    private(set) var capturedOptions: RerankOptions?

    func rerank(
        query: String,
        documents: [RerankDocument],
        options: RerankOptions
    ) async throws -> RerankResponse {
        capturedQuery = query
        capturedDocuments = documents
        capturedOptions = options
        return RerankResponse(results: [
            RerankResult(index: 0, relevanceScore: 1, document: documents.first)
        ])
    }
}
