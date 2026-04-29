import Foundation
import XCTest

@testable import Swifty_AI

final class OpenAICompatibleEmbeddingProviderTests: XCTestCase {
    private var provider: OpenAICompatibleProvider!

    override func setUp() {
        super.setUp()
        MockURLProtocol.handler = nil
        provider = OpenAICompatibleProvider(
            baseURL: "https://api.openai.com/v1",
            apiKey: "test-key",
            model: "text-embedding-3-small",
            session: .mock
        )
    }

    func testEmbedSendsStringInputAndDecodesResponse() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.handler = { request in
            capturedRequest = request
            return try mockResponse(
                statusCode: 200,
                json: [
                    "model": "text-embedding-3-small",
                    "data": [
                        ["index": 0, "embedding": [0.1, 0.2, 0.3]]
                    ],
                    "usage": ["prompt_tokens": 4, "total_tokens": 4],
                ]
            )
        }

        let response = try await provider.embed(
            "A short sentence",
            options: EmbeddingOptions(dimensions: 3)
        )

        let request = try XCTUnwrap(capturedRequest)
        let body = try request.jsonBody()

        XCTAssertEqual(request.url?.absoluteString, "https://api.openai.com/v1/embeddings")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
        XCTAssertEqual(body["model"] as? String, "text-embedding-3-small")
        XCTAssertEqual(body["input"] as? String, "A short sentence")
        XCTAssertEqual(body["dimensions"] as? Int, 3)
        XCTAssertEqual(body["encoding_format"] as? String, "float")
        XCTAssertEqual(response.embeddings, [[0.1, 0.2, 0.3]])
        XCTAssertEqual(response.model, "text-embedding-3-small")
        XCTAssertEqual(response.usage?.inputTokens, 4)
        XCTAssertEqual(response.usage?.totalTokens, 4)
    }

    func testEmbedManySendsArrayInputAndPreservesInputOrderFromIndexes() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.handler = { request in
            capturedRequest = request
            return try mockResponse(
                statusCode: 200,
                json: [
                    "model": "text-embedding-3-small",
                    "data": [
                        ["index": 1, "embedding": [0.4, 0.5]],
                        ["index": 0, "embedding": [0.1, 0.2]],
                    ],
                    "usage": ["prompt_tokens": 8, "total_tokens": 8],
                ]
            )
        }

        let response = try await provider.embedMany(["first", "second"], options: EmbeddingOptions())
        let body = try XCTUnwrap(capturedRequest).jsonBody()

        XCTAssertEqual(body["input"] as? [String], ["first", "second"])
        XCTAssertEqual(response.embeddings, [[0.1, 0.2], [0.4, 0.5]])
        XCTAssertEqual(response.usage?.inputTokens, 8)
    }

    func testEmptyEmbeddingDataThrowsInvalidResponse() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(statusCode: 200, json: ["data": []])
        }

        do {
            _ = try await provider.embed("empty", options: EmbeddingOptions())
            XCTFail("Expected invalidResponse")
        } catch AIError.invalidResponse {
            // pass
        }
    }
}
