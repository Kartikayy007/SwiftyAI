import XCTest
@testable import Swifty_AI

final class GenerateWithToolsTests: XCTestCase {
    func testGenerateWithToolsStopsWhenLoopIsFinished() async throws {
        let model = MockToolCallingModel(responses: [
            .init(text: "done", toolCalls: [], usage: TokenUsage(inputTokens: 3, outputTokens: 2), finishReason: "stop")
        ])

        let result = try await generateWithTools(model: model, prompt: "hello", tools: [])

        XCTAssertEqual(result.text, "done")
        XCTAssertEqual(result.steps.count, 1)
        XCTAssertFalse(result.isMaxStepsExceeded)
        XCTAssertEqual(result.usage?.inputTokens, 3)
        XCTAssertEqual(result.finishReason, "stop")
    }

    func testGenerateWithToolsExecutesToolAndContinues() async throws {
        let model = MockToolCallingModel(responses: [
            .init(text: "", toolCalls: [.init(id: "call_1", name: "weather", arguments: #"{"city":"Delhi"}"#)], finishReason: "tool_calls"),
            .init(text: "Sunny", toolCalls: [], finishReason: "stop")
        ])
        let tool = AITool(
            name: "weather",
            description: "Gets weather",
            parameters: ["type": "object"],
            execute: { args in
                "Weather for \(args["city"] as? String ?? "")"
            }
        )

        let result = try await generateWithTools(model: model, prompt: "weather?", tools: [tool])

        XCTAssertEqual(result.text, "Sunny")
        XCTAssertEqual(result.steps.count, 2)
        XCTAssertEqual(result.steps[0].toolResults.first?.content, "Weather for Delhi")
    }

    func testStepCountStopConditionStopsBeforeToolExecution() async throws {
        let model = MockToolCallingModel(responses: [
            .init(text: "", toolCalls: [.init(id: "call_1", name: "weather", arguments: "{}")], finishReason: "tool_calls")
        ])
        let tool = AITool(name: "weather", description: "", parameters: [:]) { _ in
            XCTFail("Tool should not execute after stop condition")
            return ""
        }

        let result = try await generateWithTools(model: model, prompt: "weather?", tools: [tool], stopWhen: [stepCountIs(1)])

        XCTAssertEqual(result.steps.count, 1)
        XCTAssertEqual(result.steps[0].toolCalls.first?.name, "weather")
        XCTAssertTrue(result.steps[0].toolResults.isEmpty)
    }

    func testMaxStepsStopsLoop() async throws {
        let model = MockToolCallingModel(responses: [
            .init(text: "", toolCalls: [.init(id: "call_1", name: "noop", arguments: "{}")], finishReason: "tool_calls"),
            .init(text: "", toolCalls: [.init(id: "call_2", name: "noop", arguments: "{}")], finishReason: "tool_calls")
        ])
        let tool = AITool(name: "noop", description: "", parameters: [:]) { _ in "ok" }

        let result = try await generateWithTools(model: model, prompt: "loop", tools: [tool], maxSteps: 2, stopWhen: [])

        XCTAssertTrue(result.isMaxStepsExceeded)
        XCTAssertEqual(result.finishReason, "max_steps")
    }

    func testDefaultToolCallingFallbackParsesJSONResponse() async throws {
        let model = PromptFallbackModel(text: #"{"text":"","toolCalls":[{"id":"call_1","name":"search","arguments":"{\"query\":\"swift\"}"}]}"#)

        let result = try await generateWithTools(model: model, prompt: "search swift", tools: [], stopWhen: [hasToolCall("search")])

        XCTAssertEqual(result.steps.first?.toolCalls.first?.name, "search")
    }
}

private final class MockToolCallingModel: AIToolCallingModel {
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

private struct PromptFallbackModel: AIToolCallingModel {
    let text: String

    func generate(_ prompt: String) async throws -> AIResponse {
        AIResponse(text: text, model: nil, usage: nil, finishReason: "stop")
    }

    func stream(_ prompt: String) -> AsyncThrowingStream<AIStreamChunk, Error> {
        AsyncThrowingStream { $0.finish() }
    }

    func stream(messages: [ChatMessage]) -> AsyncThrowingStream<AIStreamChunk, Error> {
        AsyncThrowingStream { $0.finish() }
    }
}
