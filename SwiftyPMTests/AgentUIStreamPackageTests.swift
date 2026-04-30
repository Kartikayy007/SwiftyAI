import XCTest
import SwiftyAI

final class AgentUIStreamPackageTests: XCTestCase {
    func testCreateAgentUIStreamIsPubliclyConsumable() async throws {
        let model = PackageAgentUIStreamModel(responses: [
            .init(text: "done", toolCalls: [], finishReason: "stop")
        ])

        var sawAgentStarted = false
        var finishText: String?

        for try await event in createAgentUIStream(model: model, prompt: "hello", tools: []) {
            switch event {
            case .agentStarted:
                sawAgentStarted = true
            case .agentFinished(let finish):
                finishText = finish.result.text
            default:
                break
            }
        }

        XCTAssertTrue(sawAgentStarted)
        XCTAssertEqual(finishText, "done")
    }
}

private final class PackageAgentUIStreamModel: AIToolCallingModel, @unchecked Sendable {
    private var responses: [AIToolStepResponse]

    init(responses: [AIToolStepResponse]) {
        self.responses = responses
    }

    func generate(_ prompt: String) async throws -> AIResponse {
        AIResponse(text: "", model: nil, usage: nil, finishReason: nil)
    }

    func stream(_ prompt: String) -> AsyncThrowingStream<AIStreamChunk, Error> {
        AsyncThrowingStream { $0.finish() }
    }

    func stream(messages: [ChatMessage]) -> AsyncThrowingStream<AIStreamChunk, Error> {
        AsyncThrowingStream { $0.finish() }
    }

    func generateStep(messages: [AIAgentMessage], tools: [AITool], options: GenerationOptions) async throws -> AIToolStepResponse {
        if responses.isEmpty {
            return .init(text: "done")
        }
        return responses.removeFirst()
    }
}
