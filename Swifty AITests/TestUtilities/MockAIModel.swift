import Foundation
@testable import Swifty_AI

struct MockAIModel: AIModel {
    var result: Result<AIResponse, Error>

    static func success(_ text: String) -> MockAIModel {
        MockAIModel(result: .success(AIResponse(text: text, model: nil, usage: nil, finishReason: nil)))
    }

    static func failure(_ error: Error) -> MockAIModel {
        MockAIModel(result: .failure(error))
    }

    func generate(_ prompt: String) async throws -> AIResponse {
        try result.get()
    }
}
