import XCTest
import SwiftyAI

final class MiddlewarePackageTests: XCTestCase {
    func testLanguageMiddlewarePublicAPI() async throws {
        let model = PackageMockModel(text: "<thinking>hidden</thinking>\nHello")
        let wrapped = wrapLanguageModel(
            model,
            middleware: [
                LanguageModelMiddleware { request, next in
                    var request = request
                    request.promptText += " from middleware"
                    return try await next(request)
                },
                extractReasoningMiddleware(),
            ]
        )

        let response = try await generateText(model: wrapped, prompt: "Say hi")

        XCTAssertEqual(response.text, "Hello")
        XCTAssertEqual(model.capturedPrompt, "Say hi from middleware")
    }

    func testSimulatedStreamingPublicAPI() async throws {
        let model = PackageMockModel(text: "abcdef")
        let wrapped = wrapLanguageModel(
            model,
            streamMiddleware: [simulateStreamingMiddleware(chunkSize: 3)]
        )

        var text = ""
        for try await chunk in streamText(model: wrapped, prompt: "stream") {
            text += chunk.text
        }

        XCTAssertEqual(text, "abcdef")
    }
}

private final class PackageMockModel: AIModel, @unchecked Sendable {
    private let text: String
    private(set) var capturedPrompt: String?

    init(text: String) {
        self.text = text
    }

    func generate(_ prompt: String) async throws -> AIResponse {
        capturedPrompt = prompt
        return AIResponse(text: text)
    }

    func generate(_ prompt: String, options: GenerationOptions) async throws -> AIResponse {
        try await generate(prompt)
    }

    func generate(_ prompt: [AIMessageContent], options: GenerationOptions) async throws -> AIResponse {
        capturedPrompt = prompt.compactMap(\.textValue).joined(separator: "\n")
        return AIResponse(text: text)
    }
}
