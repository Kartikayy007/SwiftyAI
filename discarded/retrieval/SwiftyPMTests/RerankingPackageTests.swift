import XCTest
import SwiftyAI

final class RerankingPackageTests: XCTestCase {
    func testRerankingPublicAPI() async throws {
        let model = PackageReranker()

        let response = try await rerank(
            model: model,
            query: "capital city",
            documents: [
                RerankDocument(text: "Washington, D.C. is the capital.", metadata: ["source": "wiki"]),
                RerankDocument("Carson City is in Nevada."),
            ],
            options: RerankOptions(topN: 1, returnDocuments: true)
        )

        XCTAssertEqual(response.id, "package-test")
        XCTAssertEqual(response.results.first?.index, 0)
        XCTAssertEqual(response.results.first?.document?.metadata["source"], "wiki")
    }

    func testCohereRerankProviderFactoryIsPublic() {
        let provider: CohereRerankProvider = .cohere(apiKey: "test-key", model: "rerank-v3.5")
        _ = provider
    }
}

private struct PackageReranker: AIRerankModel {
    func rerank(
        query: String,
        documents: [RerankDocument],
        options: RerankOptions
    ) async throws -> RerankResponse {
        RerankResponse(id: "package-test", results: [
            RerankResult(index: 0, relevanceScore: 1, document: documents.first)
        ])
    }
}
