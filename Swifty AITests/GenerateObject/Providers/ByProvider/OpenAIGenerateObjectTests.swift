import XCTest
@testable import Swifty_AI

final class OpenAIGenerateObjectTests: XCTestCase {
    private struct Movie: Codable, JSONSchemaConvertible, Sendable {
        let title: String
        let year: Int

        static var schemaName: String { "movie" }
        static var jsonSchema: [String: Any] {
            ["type": "object",
             "properties": ["title": ["type": "string"], "year": ["type": "integer"]],
             "required": ["title", "year"]]
        }
    }

    private var provider: OpenAIProvider!

    override func setUp() {
        provider = OpenAIProvider(baseURL: "https://api.openai.com/v1", apiKey: "test-key", model: "gpt-4o-mini", session: .mock)
    }

    func testOpenAIReturnsDecodedObject() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(statusCode: 200, json: [
                "id": "chatcmpl-123",
                "object": "chat.completion",
                "model": "gpt-4o-mini",
                "choices": [[
                    "index": 0,
                    "message": ["role": "assistant", "content": #"{"title":"The Matrix","year":1999}"#],
                    "finish_reason": "stop"
                ]],
                "usage": ["prompt_tokens": 50, "completion_tokens": 15, "total_tokens": 65]
            ])
        }

        let result = try await generateObject(model: provider, prompt: "suggest a sci-fi movie", as: Movie.self)
        XCTAssertEqual(result.object.title, "The Matrix")
        XCTAssertEqual(result.object.year, 1999)
        XCTAssertEqual(result.finishReason, "stop")
        XCTAssertEqual(result.usage?.outputTokens, 15)
    }
}
