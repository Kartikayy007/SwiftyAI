import XCTest
@testable import Swifty_AI

final class StreamTextTests: XCTestCase {
    func testStreamTextForwardsChunks() async throws {
        let model = MockAIStreamModel(chunks: [
            AIStreamChunk(text: "Hello", finishReason: nil, usage: nil),
            AIStreamChunk(text: " world", finishReason: "stop", usage: nil)
        ])
        var collected: [String] = []
        for try await chunk in streamText(model: model, prompt: "Hi") {
            collected.append(chunk.text)
        }
        XCTAssertEqual(collected, ["Hello", " world"])
    }

    func testStreamTextPropagatesError() async {
        let model = MockAIStreamModel(error: AIError.invalidResponse)
        do {
            for try await _ in streamText(model: model, prompt: "Hi") {}
            XCTFail("Expected error")
        } catch AIError.invalidResponse {
            // pass
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }
}

private struct MockAIStreamModel: AIStreamModel {
    var chunks: [AIStreamChunk] = []
    var error: Error? = nil

    func generate(_ prompt: String) async throws -> AIResponse {
        AIResponse(text: "", model: nil, usage: nil, finishReason: nil)
    }

    func stream(_ prompt: String) -> AsyncThrowingStream<AIStreamChunk, Error> {
        AsyncThrowingStream { continuation in
            if let error = error {
                continuation.finish(throwing: error)
                return
            }
            for chunk in chunks {
                continuation.yield(chunk)
            }
            continuation.finish()
        }
    }
}
