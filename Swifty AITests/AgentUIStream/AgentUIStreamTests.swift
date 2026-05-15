import XCTest
@testable import Swifty_AI

final class AgentUIStreamTests: XCTestCase {
    func testAgentUIStreamEmitsEventsInOrder() async throws {
        let model = MockAgentUIStreamModel(responses: [
            .init(
                text: "Checking ",
                toolCalls: [.init(id: "call_1", name: "weather", arguments: #"{"city":"Delhi"}"#)],
                finishReason: "tool_calls"
            ),
            .init(text: "Sunny", toolCalls: [], finishReason: "stop")
        ])
        let tool = AITool(name: "weather", description: "", parameters: [:]) { args in
            "Weather for \(args["city"] as? String ?? "")"
        }

        let events = try await collectEvents(
            createAgentUIStream(model: model, prompt: "weather?", tools: [tool])
        )

        XCTAssertEqual(events.map(eventName), [
            "agentStarted",
            "stepStarted",
            "modelChunk",
            "toolCallStarted",
            "toolCallFinished",
            "stepFinished",
            "stepStarted",
            "modelChunk",
            "stepFinished",
            "agentFinished"
        ])
    }

    func testAgentUIStreamEmitsModelChunks() async throws {
        let model = MockAgentUIStreamModel(responses: [
            .init(
                text: "Hello",
                toolCalls: [],
                usage: TokenUsage(inputTokens: 2, outputTokens: 1),
                finishReason: "stop"
            )
        ])

        let events = try await collectEvents(
            createAgentUIStream(model: model, prompt: "hello", tools: [])
        )

        let chunk = events.compactMap { event -> AIAgentChunk? in
            guard case .modelChunk(let chunk) = event else { return nil }
            return chunk
        }.first

        XCTAssertEqual(chunk?.text, "Hello")
        XCTAssertEqual(chunk?.stepIndex, 1)
        XCTAssertEqual(chunk?.usage?.inputTokens, 2)
        XCTAssertEqual(chunk?.finishReason, "stop")
    }

    func testAgentUIStreamEmitsToolCallEvent() async throws {
        let toolCall = AIToolCall(id: "call_1", name: "weather", arguments: #"{"city":"Delhi"}"#)
        let model = MockAgentUIStreamModel(responses: [
            .init(text: "", toolCalls: [toolCall], finishReason: "tool_calls"),
            .init(text: "done", toolCalls: [], finishReason: "stop")
        ])
        let tool = AITool(name: "weather", description: "", parameters: [:]) { _ in "ok" }

        let events = try await collectEvents(
            createAgentUIStream(model: model, prompt: "weather?", tools: [tool])
        )

        let event = events.compactMap { event -> AgentToolCallEvent? in
            guard case .toolCallStarted(let event) = event else { return nil }
            return event
        }.first

        XCTAssertEqual(event?.stepIndex, 1)
        XCTAssertEqual(event?.toolCall.id, "call_1")
        XCTAssertEqual(event?.toolCall.name, "weather")
        XCTAssertEqual(event?.toolCall.arguments, #"{"city":"Delhi"}"#)
    }

    func testAgentUIStreamEmitsToolResultEvent() async throws {
        let model = MockAgentUIStreamModel(responses: [
            .init(
                text: "",
                toolCalls: [.init(id: "call_1", name: "weather", arguments: #"{"city":"Delhi"}"#)],
                finishReason: "tool_calls"
            ),
            .init(text: "done", toolCalls: [], finishReason: "stop")
        ])
        let tool = AITool(name: "weather", description: "", parameters: [:]) { args in
            "Weather for \(args["city"] as? String ?? "")"
        }

        let events = try await collectEvents(
            createAgentUIStream(model: model, prompt: "weather?", tools: [tool])
        )

        let event = events.compactMap { event -> AgentToolResultEvent? in
            guard case .toolCallFinished(let event) = event else { return nil }
            return event
        }.first

        XCTAssertEqual(event?.stepIndex, 1)
        XCTAssertEqual(event?.toolResult.toolCallID, "call_1")
        XCTAssertEqual(event?.toolResult.name, "weather")
        XCTAssertEqual(event?.toolResult.content, "Weather for Delhi")
        XCTAssertEqual(event?.toolResult.isError, false)
    }

    func testAgentUIStreamEmitsFailedEventAndThrows() async {
        let model = FailingAgentUIStreamModel(error: TestError.modelFailed)
        var events: [AgentEvent] = []
        var thrownError: Error?

        do {
            for try await event in createAgentUIStream(model: model, prompt: "fail", tools: []) {
                events.append(event)
            }
            XCTFail("Expected stream to throw")
        } catch {
            thrownError = error
        }

        XCTAssertEqual(events.map(eventName), ["agentStarted", "stepStarted", "failed"])
        XCTAssertEqual(thrownError as? TestError, .modelFailed)

        guard case .failed(let failedError) = events.last else {
            return XCTFail("Expected final yielded event to be failed")
        }
        XCTAssertEqual(failedError as? TestError, .modelFailed)
    }

    func testAgentUIStreamEmitsFinishEvent() async throws {
        let model = MockAgentUIStreamModel(responses: [
            .init(
                text: "done",
                toolCalls: [],
                usage: TokenUsage(inputTokens: 3, outputTokens: 2),
                finishReason: "stop"
            )
        ])

        let events = try await collectEvents(
            createAgentUIStream(model: model, prompt: "hello", tools: [])
        )

        guard case .agentFinished(let event) = events.last else {
            return XCTFail("Expected final event to be agentFinished")
        }

        XCTAssertEqual(event.result.text, "done")
        XCTAssertEqual(event.result.steps.count, 1)
        XCTAssertEqual(event.result.usage?.outputTokens, 2)
        XCTAssertEqual(event.result.finishReason, "stop")
        XCTAssertFalse(event.result.isMaxStepsExceeded)
    }
}

private func collectEvents(_ stream: AsyncThrowingStream<AgentEvent, Error>) async throws -> [AgentEvent] {
    var events: [AgentEvent] = []
    for try await event in stream {
        events.append(event)
    }
    return events
}

private func eventName(_ event: AgentEvent) -> String {
    switch event {
    case .agentStarted:
        return "agentStarted"
    case .stepStarted:
        return "stepStarted"
    case .modelChunk:
        return "modelChunk"
    case .toolCallStarted:
        return "toolCallStarted"
    case .toolCallFinished:
        return "toolCallFinished"
    case .stepFinished:
        return "stepFinished"
    case .agentFinished:
        return "agentFinished"
    case .failed:
        return "failed"
    }
}

private final class MockAgentUIStreamModel: AIToolCallingModel, @unchecked Sendable {
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

private struct FailingAgentUIStreamModel: AIToolCallingModel {
    let error: TestError

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
        throw error
    }
}

private enum TestError: Error, Equatable, Sendable {
    case modelFailed
}
