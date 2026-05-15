import Foundation
import XCTest

@testable import Swifty_AI

final class MultimodalRequestEncodingTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockURLProtocol.handler = nil
    }

    func testMessagePartsPreserveTextAndAttachments() {
        let imageURL = URL(string: "https://example.com/image.png")!
        let message = ChatMessage(
            role: .user,
            parts: [
                .text("Describe this"),
                .imageURL(imageURL, detail: .low),
                .fileData(Data("hello".utf8), mediaType: .plainText, filename: "note.txt"),
            ]
        )

        XCTAssertEqual(message.content, "Describe this")
        XCTAssertEqual(message.parts.count, 3)
        XCTAssertEqual(message.parts[2].filename, "note.txt")
        XCTAssertEqual(AIMediaType.infer(from: imageURL), .png)
    }

    func testMessageContentAndPartsStayInSync() {
        var message = ChatMessage(role: .assistant, content: "")

        message.content += "Hello"
        XCTAssertEqual(message.parts.first?.textValue, "Hello")

        message.parts = [.text("Updated"), .imageURL(URL(string: "https://example.com/image.png")!)]
        XCTAssertEqual(message.content, "Updated")
    }

    func testOpenAICompatibleEncodesMultipartPrompt() async throws {
        var body: [String: Any]?
        MockURLProtocol.handler = { request in
            body = try Self.jsonBody(from: request)
            return try mockResponse(
                statusCode: 200,
                json: [
                    "choices": [["message": ["content": "ok"], "finish_reason": "stop"]]
                ])
        }

        let provider = OpenAICompatibleProvider(
            baseURL: "https://api.openai.com/v1",
            apiKey: "test-key",
            model: "gpt-4o",
            session: .mock
        )
        _ = try await provider.generate(
            [
                .text("Describe this image"),
                .imageURL(URL(string: "https://example.com/photo.jpg")!, detail: .high),
                .audioData(Data("sound".utf8), mediaType: .mp3, filename: "clip.mp3"),
                .pdfData(Data("pdf".utf8), filename: "brief.pdf"),
            ],
            options: GenerationOptions(system: "Be concise.")
        )

        let messages = try XCTUnwrap(body?["messages"] as? [[String: Any]])
        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages[0]["role"] as? String, "system")

        let parts = try XCTUnwrap(messages[1]["content"] as? [[String: Any]])
        XCTAssertEqual(parts[0]["type"] as? String, "text")
        XCTAssertEqual(parts[0]["text"] as? String, "Describe this image")

        let imageURL = try XCTUnwrap(parts[1]["image_url"] as? [String: Any])
        XCTAssertEqual(parts[1]["type"] as? String, "image_url")
        XCTAssertEqual(imageURL["url"] as? String, "https://example.com/photo.jpg")
        XCTAssertEqual(imageURL["detail"] as? String, "high")

        let audio = try XCTUnwrap(parts[2]["input_audio"] as? [String: Any])
        XCTAssertEqual(parts[2]["type"] as? String, "input_audio")
        XCTAssertEqual(audio["format"] as? String, "mp3")

        let file = try XCTUnwrap(parts[3]["file"] as? [String: Any])
        XCTAssertEqual(parts[3]["type"] as? String, "file")
        XCTAssertEqual(file["filename"] as? String, "brief.pdf")
        XCTAssertEqual(file["file_data"] as? String, "data:application/pdf;base64,cGRm")
    }

    func testAnthropicEncodesImageAndPDFBlocks() async throws {
        var body: [String: Any]?
        MockURLProtocol.handler = { request in
            body = try Self.jsonBody(from: request)
            return try mockResponse(
                statusCode: 200,
                json: [
                    "content": [["type": "text", "text": "ok"]],
                    "stop_reason": "end_turn",
                ])
        }

        let provider = AnthropicProvider(apiKey: "test-key", model: "claude-sonnet", session: .mock)
        _ = try await provider.generate(
            [
                .text("Summarize these assets"),
                .imageBase64("aW1hZ2U=", mediaType: .png),
                .pdfURL(URL(string: "https://example.com/report.pdf")!, filename: "report.pdf"),
            ],
            options: GenerationOptions()
        )

        let messages = try XCTUnwrap(body?["messages"] as? [[String: Any]])
        let content = try XCTUnwrap(messages.first?["content"] as? [[String: Any]])

        XCTAssertEqual(content[0]["type"] as? String, "text")
        XCTAssertEqual(content[1]["type"] as? String, "image")
        let imageSource = try XCTUnwrap(content[1]["source"] as? [String: Any])
        XCTAssertEqual(imageSource["type"] as? String, "base64")
        XCTAssertEqual(imageSource["media_type"] as? String, "image/png")
        XCTAssertEqual(imageSource["data"] as? String, "aW1hZ2U=")

        XCTAssertEqual(content[2]["type"] as? String, "document")
        let documentSource = try XCTUnwrap(content[2]["source"] as? [String: Any])
        XCTAssertEqual(documentSource["type"] as? String, "url")
        XCTAssertEqual(documentSource["url"] as? String, "https://example.com/report.pdf")
    }

    func testAnthropicRejectsUnsupportedAudioInput() async throws {
        let provider = AnthropicProvider(apiKey: "test-key", model: "claude-sonnet", session: .mock)

        do {
            _ = try await provider.generate(
                [.text("Transcribe"), .audioBase64("c291bmQ=", mediaType: .mp3)],
                options: GenerationOptions()
            )
            XCTFail("Expected unsupportedFeature")
        } catch AIError.unsupportedFeature(let message) {
            XCTAssertTrue(message.contains("text, images, and PDFs"))
        }
    }

    func testGeminiEncodesInlineDataAndFileData() async throws {
        var body: [String: Any]?
        MockURLProtocol.handler = { request in
            body = try Self.jsonBody(from: request)
            return try mockResponse(
                statusCode: 200,
                json: [
                    "candidates": [
                        ["content": ["parts": [["text": "ok"]]], "finishReason": "STOP"]
                    ]
                ])
        }

        let provider = GeminiProvider(apiKey: "test-key", model: "gemini-2.5-flash", session: .mock)
        _ = try await provider.generate(
            [
                .text("Analyze"),
                .imageData(Data("image".utf8), mediaType: .jpeg),
                .fileURL(URL(string: "https://example.com/notes.txt")!, mediaType: .plainText, filename: "notes.txt"),
            ],
            options: GenerationOptions()
        )

        let contents = try XCTUnwrap(body?["contents"] as? [[String: Any]])
        let parts = try XCTUnwrap(contents.first?["parts"] as? [[String: Any]])
        XCTAssertEqual(parts[0]["text"] as? String, "Analyze")

        let inlineData = try XCTUnwrap(parts[1]["inline_data"] as? [String: Any])
        XCTAssertEqual(inlineData["mime_type"] as? String, "image/jpeg")
        XCTAssertEqual(inlineData["data"] as? String, "aW1hZ2U=")

        let fileData = try XCTUnwrap(parts[2]["file_data"] as? [String: Any])
        XCTAssertEqual(fileData["mime_type"] as? String, "text/plain")
        XCTAssertEqual(fileData["file_uri"] as? String, "https://example.com/notes.txt")
    }

    func testGenerateObjectAppendsSchemaInstructionToMultipartPrompt() async throws {
        let model = CapturingObjectModel()
        _ = try await generateObject(
            model: model,
            prompt: [
                .text("Read this image"),
                .imageURL(URL(string: "https://example.com/recipe.png")!),
            ],
            output: Output<RecipeName>.object(RecipeName.self)
        )

        let parts = try XCTUnwrap(model.capturedParts)
        XCTAssertEqual(parts.count, 3)
        XCTAssertEqual(parts[0].textValue, "Read this image")
        XCTAssertNil(parts[1].textValue)
        XCTAssertTrue(parts[2].textValue?.contains("Respond with valid JSON matching this schema") == true)
    }

    private static func jsonBody(from request: URLRequest) throws -> [String: Any] {
        let data = try XCTUnwrap(request.httpBody)
        let value = try JSONSerialization.jsonObject(with: data)
        return try XCTUnwrap(value as? [String: Any])
    }
}

private struct RecipeName: Codable, AISchemaConvertible {
    let name: String

    static var aiSchema: AISchema {
        .object(properties: ["name": .string(minLength: 1)], required: ["name"])
    }
}

private final class CapturingObjectModel: AIModel, @unchecked Sendable {
    private(set) var capturedParts: [AIMessageContent]?

    func generate(_ prompt: String) async throws -> AIResponse {
        AIResponse(text: #"{"name":"Pasta"}"#, model: nil, usage: nil, finishReason: "stop")
    }

    func generate(_ prompt: [AIMessageContent], options: GenerationOptions) async throws -> AIResponse {
        capturedParts = prompt
        return AIResponse(text: #"{"name":"Pasta"}"#, model: nil, usage: nil, finishReason: "stop")
    }
}
