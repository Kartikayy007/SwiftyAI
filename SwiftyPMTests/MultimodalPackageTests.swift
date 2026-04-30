import Foundation
import XCTest
import SwiftyAI

final class MultimodalPackageTests: XCTestCase {
    func testPublicMessagePartsAPI() {
        let url = URL(string: "https://example.com/photo.jpeg")!
        let message = ChatMessage(role: .user, parts: [
            .text("Describe this"),
            .imageURL(url, detail: .high),
        ])

        XCTAssertEqual(message.content, "Describe this")
        XCTAssertEqual(message.parts.count, 2)
        XCTAssertEqual(message.parts.first?.textValue, "Describe this")
        XCTAssertEqual(AIMediaType.infer(from: url), .jpeg)
    }

    func testContentAndPartsStayInSync() {
        var message = ChatMessage(role: .assistant, content: "")
        message.content += "Hello"
        XCTAssertEqual(message.parts.first?.textValue, "Hello")

        message.parts = [.text("Updated")]
        XCTAssertEqual(message.content, "Updated")
    }

    func testGenerateTextAcceptsMultipartPrompt() async throws {
        let model = CapturingModel()
        let response = try await generateText(
            model: model,
            prompt: [
                .text("Analyze"),
                .fileData(Data("hello".utf8), mediaType: .plainText, filename: "note.txt"),
            ]
        )

        XCTAssertEqual(response.text, "ok")
        XCTAssertEqual(model.capturedParts?.count, 2)
        XCTAssertEqual(model.capturedParts?.last?.filename, "note.txt")
    }

    func testGenerateObjectAcceptsMultipartPrompt() async throws {
        let model = CapturingModel(responseText: #"{"name":"Pasta"}"#)
        let result = try await generateObject(
            model: model,
            prompt: [
                .text("Read the image"),
                .imageURL(URL(string: "https://example.com/recipe.png")!),
            ],
            output: Output<Item>.object(Item.self)
        )

        XCTAssertEqual(result.object.name, "Pasta")
        XCTAssertEqual(model.capturedParts?.count, 3)
        XCTAssertTrue(model.capturedParts?.last?.textValue?.contains("Respond with valid JSON") == true)
    }
}

private struct Item: Codable, AISchemaConvertible {
    let name: String

    static var aiSchema: AISchema {
        .object(properties: ["name": .string(minLength: 1)], required: ["name"])
    }
}

private final class CapturingModel: AIModel, @unchecked Sendable {
    private let responseText: String
    private(set) var capturedParts: [AIMessageContent]?

    init(responseText: String = "ok") {
        self.responseText = responseText
    }

    func generate(_ prompt: String) async throws -> AIResponse {
        AIResponse(text: responseText, model: nil, usage: nil, finishReason: "stop")
    }

    func generate(_ prompt: [AIMessageContent], options: GenerationOptions) async throws -> AIResponse {
        capturedParts = prompt
        return AIResponse(text: responseText, model: nil, usage: nil, finishReason: "stop")
    }
}
