import XCTest
@testable import Swifty_AI

final class AICompletionTests: XCTestCase {
    @MainActor
    func testInitialStateIsEmpty() {
        let completion = AICompletion(model: ControlledAIModel())

        XCTAssertEqual(completion.input, "")
        XCTAssertEqual(completion.output, "")
        XCTAssertEqual(completion.prompt, "")
        XCTAssertEqual(completion.completion, "")
        XCTAssertFalse(completion.isLoading)
        XCTAssertNil(completion.error)
    }

    @MainActor
    func testAliasesUpdateUnderlyingState() {
        let completion = AICompletion(model: ControlledAIModel())

        completion.prompt = "Draft"
        completion.completion = "Result"

        XCTAssertEqual(completion.input, "Draft")
        XCTAssertEqual(completion.output, "Result")
    }

    @MainActor
    func testSendStartsLoadingAndWritesOutput() async {
        let model = ControlledAIModel()
        let completion = AICompletion(model: model)
        completion.input = "Hello"
        completion.output = "Old"

        completion.send()

        XCTAssertTrue(completion.isLoading)
        XCTAssertEqual(completion.output, "")
        XCTAssertNil(completion.error)

        await model.finish(with: .success(AIResponse(text: "Hi there")))
        await waitUntil { !completion.isLoading }

        XCTAssertEqual(completion.output, "Hi there")
        XCTAssertFalse(completion.isLoading)
        XCTAssertNil(completion.error)
    }

    @MainActor
    func testSendCapturesError() async {
        let model = ControlledAIModel()
        let completion = AICompletion(model: model)
        completion.input = "Hello"

        completion.send()
        await model.finish(with: .failure(AIError.invalidResponse))
        await waitUntil { !completion.isLoading }

        XCTAssertNotNil(completion.error)
        XCTAssertEqual(completion.output, "")
        XCTAssertFalse(completion.isLoading)
    }

    @MainActor
    func testStopCancelsInFlightGeneration() async {
        let model = ControlledAIModel()
        let completion = AICompletion(model: model)
        completion.input = "Hello"

        completion.send()
        await waitUntil { await model.hasStarted }

        completion.stop()
        await waitUntil { !completion.isLoading }

        XCTAssertFalse(completion.isLoading)
        XCTAssertEqual(completion.output, "")
        XCTAssertNil(completion.error)
    }

    @MainActor
    func testResetClearsStateAndCancelsInFlightGeneration() async {
        let model = ControlledAIModel()
        let completion = AICompletion(model: model)
        completion.input = "Hello"
        completion.output = "Old"
        completion.error = AIError.invalidResponse

        completion.send()
        await waitUntil { await model.hasStarted }

        completion.reset()

        XCTAssertEqual(completion.input, "")
        XCTAssertEqual(completion.output, "")
        XCTAssertFalse(completion.isLoading)
        XCTAssertNil(completion.error)
    }
}

private final class ControlledAIModel: AIModel, @unchecked Sendable {
    private let state = ControlledAIModelState()

    var hasStarted: Bool {
        get async {
            await state.hasStarted
        }
    }

    func finish(with result: Result<AIResponse, Error>) async {
        await state.finish(with: result)
    }

    func generate(_ prompt: String) async throws -> AIResponse {
        try await state.waitForResult()
    }
}

private actor ControlledAIModelState {
    private var continuation: CheckedContinuation<Result<AIResponse, Error>, Never>?
    private var pendingResult: Result<AIResponse, Error>?
    private(set) var hasStarted = false

    func waitForResult() async throws -> AIResponse {
        hasStarted = true
        if let pendingResult {
            self.pendingResult = nil
            return try pendingResult.get()
        }

        let result = await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                if let pendingResult {
                    self.pendingResult = nil
                    continuation.resume(returning: pendingResult)
                } else {
                    self.continuation = continuation
                }
            }
        } onCancel: {
            Task {
                await self.finish(with: .failure(CancellationError()))
            }
        }

        return try result.get()
    }

    func finish(with result: Result<AIResponse, Error>) {
        if let continuation {
            continuation.resume(returning: result)
            self.continuation = nil
        } else {
            pendingResult = result
        }
    }
}

@MainActor
private func waitUntil(
    timeout: Duration = .seconds(1),
    condition: @escaping @MainActor () async -> Bool
) async {
    let deadline = ContinuousClock.now.advanced(by: timeout)
    while ContinuousClock.now < deadline {
        if await condition() {
            return
        }
        try? await Task.sleep(for: .milliseconds(10))
    }
}
