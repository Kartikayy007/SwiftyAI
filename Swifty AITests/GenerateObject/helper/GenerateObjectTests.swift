import XCTest
@testable import Swifty_AI

final class GenerateObjectTests: XCTestCase {
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

    func testDecodesValidJSON() async throws {
        let mock = MockAIModel.success(#"{"title":"Dune","year":1984}"#)
        let result = try await generateObject(model: mock, prompt: "sci-fi movie", as: Movie.self)
        XCTAssertEqual(result.object.title, "Dune")
        XCTAssertEqual(result.object.year, 1984)
    }

    func testPreservesUsageAndFinishReason() async throws {
        let response = AIResponse(
            text: #"{"title":"Alien","year":1979}"#,
            model: "gpt-4o",
            usage: TokenUsage(inputTokens: 10, outputTokens: 20),
            finishReason: "stop"
        )
        let mock = MockAIModel(result: .success(response))
        let result = try await generateObject(model: mock, prompt: "horror sci-fi", as: Movie.self)
        XCTAssertEqual(result.usage?.inputTokens, 10)
        XCTAssertEqual(result.usage?.outputTokens, 20)
        XCTAssertEqual(result.finishReason, "stop")
        XCTAssertEqual(result.model, "gpt-4o")
    }

    func testThrowsOnInvalidJSON() async throws {
        let mock = MockAIModel.success("not json at all")
        do {
            _ = try await generateObject(model: mock, prompt: "movie", as: Movie.self)
            XCTFail("Expected throw")
        } catch AIError.decodingError {
            // expected
        }
    }

    func testThrowsOnEmptyResponse() async throws {
        let mock = MockAIModel.success("")
        do {
            _ = try await generateObject(model: mock, prompt: "movie", as: Movie.self)
            XCTFail("Expected throw")
        } catch AIError.decodingError {
            // expected
        }
    }

    func testSchemaInjectedInPrompt() async throws {
        var capturedPrompt = ""
        struct CapturingModel: AIModel {
            let capture: (String) -> Void
            func generate(_ prompt: String) async throws -> AIResponse {
                capture(prompt)
                return AIResponse(text: #"{"title":"X","year":2000}"#, model: nil, usage: nil, finishReason: nil)
            }
        }
        let model = CapturingModel { capturedPrompt = $0 }
        _ = try await generateObject(model: model, prompt: "test prompt", as: Movie.self)
        XCTAssertTrue(capturedPrompt.contains("title"))
        XCTAssertTrue(capturedPrompt.contains("integer"))
    }

    func testPromptForwardedToModel() async throws {
        var capturedPrompt = ""
        struct CapturingModel: AIModel {
            let capture: (String) -> Void
            func generate(_ prompt: String) async throws -> AIResponse {
                capture(prompt)
                return AIResponse(text: #"{"title":"X","year":2000}"#, model: nil, usage: nil, finishReason: nil)
            }
        }
        let model = CapturingModel { capturedPrompt = $0 }
        _ = try await generateObject(model: model, prompt: "suggest a classic sci-fi movie", as: Movie.self)
        XCTAssertTrue(capturedPrompt.contains("suggest a classic sci-fi movie"))
    }

    func testStripsMarkdownFences() async throws {
        let json = "```json\n{\"title\":\"Blade Runner\",\"year\":1982}\n```"
        let mock = MockAIModel.success(json)
        let result = try await generateObject(model: mock, prompt: "movie", as: Movie.self)
        XCTAssertEqual(result.object.title, "Blade Runner")
        XCTAssertEqual(result.object.year, 1982)
    }

    func testStripsMarkdownFencesNoLanguage() async throws {
        let json = "```\n{\"title\":\"Metropolis\",\"year\":1927}\n```"
        let mock = MockAIModel.success(json)
        let result = try await generateObject(model: mock, prompt: "movie", as: Movie.self)
        XCTAssertEqual(result.object.title, "Metropolis")
        XCTAssertEqual(result.object.year, 1927)
    }

    // Documents that JSONDecoder ignores unknown keys by default.
    // Real LLMs often return extra fields not in the schema — this is expected and safe.
    func testExtraKeysInResponseAreIgnored() async throws {
        let json = #"{"title":"2001: A Space Odyssey","year":1968,"director":"Kubrick","runtime":149}"#
        let mock = MockAIModel.success(json)
        let result = try await generateObject(model: mock, prompt: "movie", as: Movie.self)
        XCTAssertEqual(result.object.title, "2001: A Space Odyssey")
        XCTAssertEqual(result.object.year, 1968)
    }
}
