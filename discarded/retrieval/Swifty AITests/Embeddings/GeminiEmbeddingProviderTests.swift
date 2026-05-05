import Foundation
import XCTest

@testable import Swifty_AI

final class GeminiEmbeddingProviderTests: XCTestCase {
    private var provider: GeminiProvider!

    override func setUp() {
        super.setUp()
        MockURLProtocol.handler = nil
        provider = GeminiProvider(apiKey: "test-key", model: "gemini-embedding-001", session: .mock)
    }

    func testEmbedSendsContentRequestAndDecodesResponse() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.handler = { request in
            capturedRequest = request
            return try mockResponse(
                statusCode: 200,
                json: [
                    "embedding": ["values": [0.1, 0.2, 0.3]],
                    "usageMetadata": ["promptTokenCount": 5, "totalTokenCount": 5],
                ]
            )
        }

        let response = try await provider.embed(
            "Swift embeddings",
            options: EmbeddingOptions(
                dimensions: 3,
                taskType: .semanticSimilarity
            )
        )

        let request = try XCTUnwrap(capturedRequest)
        let body = try request.jsonBody()
        let content = try XCTUnwrap(body["content"] as? [String: Any])
        let parts = try XCTUnwrap(content["parts"] as? [[String: Any]])

        XCTAssertEqual(
            request.url?.absoluteString,
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-001:embedContent"
        )
        XCTAssertEqual(request.value(forHTTPHeaderField: "x-goog-api-key"), "test-key")
        XCTAssertEqual(body["model"] as? String, "models/gemini-embedding-001")
        XCTAssertEqual(parts.first?["text"] as? String, "Swift embeddings")
        XCTAssertEqual(body["outputDimensionality"] as? Int, 3)
        XCTAssertEqual(body["taskType"] as? String, "SEMANTIC_SIMILARITY")
        XCTAssertEqual(response.embeddings, [[0.1, 0.2, 0.3]])
        XCTAssertEqual(response.model, "gemini-embedding-001")
        XCTAssertEqual(response.usage?.inputTokens, 5)
        XCTAssertEqual(response.usage?.totalTokens, 5)
    }

    func testEmbedManySendsBatchRequestAndDecodesResponse() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.handler = { request in
            capturedRequest = request
            return try mockResponse(
                statusCode: 200,
                json: [
                    "embeddings": [
                        ["values": [0.1, 0.2]],
                        ["values": [0.3, 0.4]],
                    ],
                    "usageMetadata": ["inputTokenCount": 7, "totalTokenCount": 7],
                ]
            )
        }

        let response = try await provider.embedMany(
            ["first", "second"],
            options: EmbeddingOptions(dimensions: 2, taskType: .retrievalDocument, title: "Docs")
        )

        let request = try XCTUnwrap(capturedRequest)
        let body = try request.jsonBody()
        let requests = try XCTUnwrap(body["requests"] as? [[String: Any]])
        let firstContent = try XCTUnwrap(requests.first?["content"] as? [String: Any])
        let firstParts = try XCTUnwrap(firstContent["parts"] as? [[String: Any]])

        XCTAssertEqual(
            request.url?.absoluteString,
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-001:batchEmbedContents"
        )
        XCTAssertEqual(requests.count, 2)
        XCTAssertEqual(requests.first?["model"] as? String, "models/gemini-embedding-001")
        XCTAssertEqual(requests.first?["outputDimensionality"] as? Int, 2)
        XCTAssertEqual(requests.first?["taskType"] as? String, "RETRIEVAL_DOCUMENT")
        XCTAssertEqual(requests.first?["title"] as? String, "Docs")
        XCTAssertEqual(firstParts.first?["text"] as? String, "first")
        XCTAssertEqual(response.embeddings, [[0.1, 0.2], [0.3, 0.4]])
        XCTAssertEqual(response.usage?.inputTokens, 7)
    }

    func testEmptyEmbeddingThrowsInvalidResponse() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(statusCode: 200, json: ["embedding": ["values": []]])
        }

        do {
            _ = try await provider.embed("empty", options: EmbeddingOptions())
            XCTFail("Expected invalidResponse")
        } catch AIError.invalidResponse {
            // pass
        }
    }
}
