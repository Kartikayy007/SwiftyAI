import XCTest
import SwiftyAI

final class SwiftUIHooksPackageTests: XCTestCase {
    @MainActor
    func testAICompletionIsAvailableFromPackageProduct() {
        let completion = AICompletion(model: PackageAIModel())

        completion.prompt = "Hello"
        completion.completion = "Hi"
        completion.stop()
        completion.reset()

        XCTAssertEqual(completion.input, "")
        XCTAssertEqual(completion.output, "")
        XCTAssertFalse(completion.isLoading)
        XCTAssertNil(completion.error)
    }

    @MainActor
    func testAIChatIsAvailableFromPackageProduct() {
        let chat = AIChat(model: PackageStreamModel())

        chat.input = "Hello"
        chat.send()
        chat.stop()
        chat.reset()

        XCTAssertTrue(chat.messages.isEmpty)
        XCTAssertEqual(chat.input, "")
        XCTAssertFalse(chat.isLoading)
        XCTAssertNil(chat.error)
    }
}

private struct PackageAIModel: AIModel {
    func generate(_ prompt: String) async throws -> AIResponse {
        AIResponse(text: "ok")
    }
}

private struct PackageStreamModel: AIStreamModel {
    func generate(_ prompt: String) async throws -> AIResponse {
        AIResponse(text: "ok")
    }

    func stream(_ prompt: String) -> AsyncThrowingStream<AIStreamChunk, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(AIStreamChunk(text: "ok"))
            continuation.finish()
        }
    }
}
