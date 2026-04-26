import Foundation
@testable import Swifty_AI

final class MockStreamModel: AIStreamModel {
    var chunks: [AIStreamChunk] = []
    var shouldThrow: Error? = nil
    var capturedMessages: [ChatMessage] = []

    func generate(_ prompt: String) async throws -> AIResponse {
        AIResponse(text: "", model: nil, usage: nil, finishReason: nil)
    }

    func stream(_ prompt: String) -> AsyncThrowingStream<AIStreamChunk, Error> {
        stream(messages: [ChatMessage(role: .user, content: prompt)])
    }

    func stream(messages: [ChatMessage]) -> AsyncThrowingStream<AIStreamChunk, Error> {
        capturedMessages = messages
        let chunks = self.chunks
        let error = self.shouldThrow
        return AsyncThrowingStream { continuation in
            Task {
                if let error {
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
}
