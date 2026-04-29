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

    func testTypedToolDecodesInputAndEncodesOutput() async throws {
        struct Input: Decodable {
            let bill: Double
            let percent: Double
        }
        struct Output: Encodable {
            let total: Double
        }

        let tipTool = tool(
            name: "tip",
            description: "Calculates tip",
            inputSchema: .object(properties: ["bill": .number(), "percent": .number()]),
            outputSchema: .object(properties: ["total": .number()])
        ) { (input: Input) in
            Output(total: input.bill + input.bill * input.percent / 100)
        }

        let result = try await tipTool.execute(["bill": 100.0, "percent": 20.0])

        XCTAssertTrue(result.contains(#""total":120"#))
        XCTAssertNotNil(tipTool.outputSchema)
    }

    func testDynamicToolReceivesRawArguments() async throws {
        let search = dynamicTool(
            name: "search",
            description: "Searches",
            inputSchema: .object(properties: ["query": .string()])
        ) { args in
            "query=\(args["query"] as? String ?? "")"
        }

        let result = try await search.execute(["query": "swift"])

        XCTAssertEqual(result, "query=swift")
    }

    func testToolCallInterceptionCanReplaceArguments() async throws {
        let model = MockToolCallingModel(responses: [
            .init(text: "", toolCalls: [.init(id: "call_1", name: "echo", arguments: #"{"value":"old"}"#)], finishReason: "tool_calls"),
            .init(text: "done", toolCalls: [], finishReason: "stop")
        ])
        let echo = AITool(name: "echo", description: "", parameters: [:]) { args in
            args["value"] as? String ?? ""
        }

        let result = try await generateWithTools(
            model: model,
            prompt: "echo",
            tools: [echo],
            toolOptions: .init(onToolCall: { _ in .replaceArguments(#"{"value":"new"}"#) })
        )

        XCTAssertEqual(result.steps.first?.toolResults.first?.content, "new")
    }

    func testApprovalCanRejectToolCall() async throws {
        let model = MockToolCallingModel(responses: [
            .init(text: "", toolCalls: [.init(id: "call_1", name: "delete", arguments: "{}")], finishReason: "tool_calls"),
            .init(text: "blocked", toolCalls: [], finishReason: "stop")
        ])
        let dangerous = AITool(name: "delete", description: "", parameters: [:]) { _ in
            XCTFail("Rejected tool must not execute")
            return ""
        }

        let result = try await generateWithTools(
            model: model,
            prompt: "delete",
            tools: [dangerous],
            toolOptions: .init(approval: { _ in .reject(reason: "Needs human approval") })
        )

        XCTAssertEqual(result.steps.first?.toolResults.first?.content, "Needs human approval")
        XCTAssertEqual(result.steps.first?.toolResults.first?.isError, true)
    }

    func testTelemetryReceivesToolLifecycleEvents() async throws {
        let model = MockToolCallingModel(responses: [
            .init(text: "", toolCalls: [.init(id: "call_1", name: "noop", arguments: "{}")], finishReason: "tool_calls"),
            .init(text: "done", toolCalls: [], finishReason: "stop")
        ])
        let noop = AITool(name: "noop", description: "", parameters: [:]) { _ in "ok" }
        var eventCount = 0

        _ = try await generateWithTools(
            model: model,
            prompt: "noop",
            tools: [noop],
            toolOptions: .init(onTelemetry: { _ in eventCount += 1 })
        )

        XCTAssertGreaterThanOrEqual(eventCount, 4)
    }

    func testParallelToolCallsRunConcurrentlyAndPreserveOrder() async throws {
        actor ConcurrencyProbe {
            var active = 0
            var maxActive = 0

            func started() {
                active += 1
                maxActive = max(maxActive, active)
            }

            func finished() {
                active -= 1
            }
        }

        let probe = ConcurrencyProbe()
        let model = MockToolCallingModel(responses: [
            .init(text: "", toolCalls: [
                .init(id: "call_1", name: "slow", arguments: #"{"value":"first"}"#),
                .init(id: "call_2", name: "slow", arguments: #"{"value":"second"}"#)
            ], finishReason: "tool_calls"),
            .init(text: "done", toolCalls: [], finishReason: "stop")
        ])
        let slow = AITool(name: "slow", description: "", parameters: [:]) { args in
            await probe.started()
            try await Task.sleep(nanoseconds: 50_000_000)
            await probe.finished()
            return args["value"] as? String ?? ""
        }

        let result = try await generateWithTools(
            model: model,
            prompt: "parallel",
            tools: [slow],
            toolOptions: .init(parallelToolCalls: true)
        )

        XCTAssertEqual(result.steps.first?.toolResults.map(\.content), ["first", "second"])
        let maxActive = await probe.maxActive
        XCTAssertEqual(maxActive, 2)
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
