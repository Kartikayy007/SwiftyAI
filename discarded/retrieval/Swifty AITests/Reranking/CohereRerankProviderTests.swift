import XCTest

@testable import Swifty_AI

final class CohereRerankProviderTests: XCTestCase {
    private var provider: CohereRerankProvider!

    override func setUp() {
        super.setUp()
        MockURLProtocol.handler = nil
        provider = CohereRerankProvider(
            apiKey: "test-key",
            model: "rerank-v3.5",
            session: .mock
        )
    }

    func testSendsCohereRerankRequestAndDecodesReturnedDocuments() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.handler = { request in
            capturedRequest = request
            return try mockResponse(
                statusCode: 200,
                json: [
                    "id": "rerank-123",
                    "results": [
                        [
                            "index": 1,
                            "relevance_score": 0.98,
                            "document": ["text": "Washington, D.C. is the capital of the United States."],
                        ],
                        [
                            "index": 0,
                            "relevance_score": 0.12,
                            "document": ["text": "Carson City is the capital of Nevada."],
                        ],
                    ],
                ])
        }

        let response = try await provider.rerank(
            query: "What is the capital of the United States?",
            documents: [
                "Carson City is the capital of Nevada.",
                "Washington, D.C. is the capital of the United States.",
            ],
            options: RerankOptions(
                topN: 2,
                returnDocuments: true,
                headers: ["X-Client-Name": "swifty-ai-tests"]
            )
        )

        XCTAssertEqual(capturedRequest?.url?.absoluteString, "https://api.cohere.com/v1/rerank")
        XCTAssertEqual(capturedRequest?.httpMethod, "POST")
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "X-Client-Name"), "swifty-ai-tests")

        let body = try XCTUnwrap(capturedRequest?.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["model"] as? String, "rerank-v3.5")
        XCTAssertEqual(json["query"] as? String, "What is the capital of the United States?")
        XCTAssertEqual(json["top_n"] as? Int, 2)
        XCTAssertEqual(json["return_documents"] as? Bool, true)
        XCTAssertEqual(
            json["documents"] as? [String],
            [
                "Carson City is the capital of Nevada.",
                "Washington, D.C. is the capital of the United States.",
            ]
        )

        XCTAssertEqual(response.id, "rerank-123")
        XCTAssertEqual(response.model, "rerank-v3.5")
        XCTAssertEqual(response.results.map(\.index), [1, 0])
        XCTAssertEqual(response.results[0].relevanceScore, 0.98)
        XCTAssertEqual(response.results[0].document?.text, "Washington, D.C. is the capital of the United States.")
    }

    func testEncodesMetadataDocumentsAsCohereObjects() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.handler = { request in
            capturedRequest = request
            return try mockResponse(
                statusCode: 200,
                json: [
                    "results": [
                        ["index": 0, "relevance_score": 0.9]
                    ]
                ])
        }

        _ = try await provider.rerank(
            query: "vacation policy",
            documents: [
                RerankDocument(text: "Employees receive paid vacation.", metadata: ["title": "Benefits"])
            ]
        )

        let body = try XCTUnwrap(capturedRequest?.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let documents = try XCTUnwrap(json["documents"] as? [[String: String]])
        XCTAssertEqual(documents.first?["text"], "Employees receive paid vacation.")
        XCTAssertEqual(documents.first?["title"], "Benefits")
    }

    func testDecodesDirectReturnedTextShape() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(
                statusCode: 200,
                json: [
                    "results": [
                        [
                            "index": 0,
                            "relevance_score": 0.7,
                            "text": "Direct returned text",
                        ]
                    ]
                ])
        }

        let response = try await provider.rerank(query: "query", documents: ["Direct returned text"])

        XCTAssertEqual(response.results.first?.document?.text, "Direct returned text")
    }

    func testAPIErrorThrowsCorrectly() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(statusCode: 401, json: ["message": "invalid api token"])
        }

        do {
            _ = try await provider.rerank(query: "query", documents: ["document"])
            XCTFail("Expected apiError")
        } catch AIError.apiError(let statusCode, let message) {
            XCTAssertEqual(statusCode, 401)
            XCTAssertEqual(message, "invalid api token")
        }
    }
}
