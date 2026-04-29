import XCTest
@testable import Swifty_AI

final class AIChatTests: XCTestCase {
    @MainActor
    func testInitialStateIsEmpty() {
        let chat = AIChat(model: ControlledStreamModel(chunks: []))

        XCTAssertTrue(chat.messages.isEmpty)
        XCTAssertEqual(chat.input, "")
        XCTAssertFalse(chat.isLoading)
        XCTAssertNil(chat.error)
    }

    @MainActor
    func testSendAppendsOptimisticUserMessageAndClearsInput() {
        let chat = AIChat(model: ControlledStreamModel(chunks: [.init(text: "Hi")]))
        chat.input = "Hello"

        chat.send()

        XCTAssertEqual(chat.input, "")
        XCTAssertTrue(chat.isLoading)
        XCTAssertEqual(chat.messages.first?.role, .user)
        XCTAssertEqual(chat.messages.first?.content, "Hello")
        XCTAssertEqual(chat.messages.last?.role, .assistant)

        chat.stop()
    }

    @MainActor
    func testAssistantMessageAccumulatesStreamedChunks() async {
        let model = ControlledStreamModel(chunks: [
            AIStreamChunk(text: "Hello"),
            AIStreamChunk(text: " world", finishReason: "stop")
        ])
        let chat = AIChat(model: model)
        chat.input = "Hi"

        chat.send()
        await waitUntil { !chat.isLoading }

        XCTAssertEqual(chat.messages.last?.role, .assistant)
        XCTAssertEqual(chat.messages.last?.content, "Hello world")
        XCTAssertNil(chat.error)
    }

    @MainActor
    func testIsLoadingTransitionsDuringStream() async {
        let model = ControlledStreamModel(chunks: [AIStreamChunk(text: "Done")], delay: .milliseconds(100))
        let chat = AIChat(model: model)
        chat.input = "Hi"

        chat.send()

        XCTAssertTrue(chat.isLoading)
        await waitUntil { !chat.isLoading }
        XCTAssertFalse(chat.isLoading)
    }

    @MainActor
    func testStreamErrorSetsError() async {
        let model = ControlledStreamModel(chunks: [], error: AIError.invalidResponse)
        let chat = AIChat(model: model)
        chat.input = "Hi"

        chat.send()
        await waitUntil { !chat.isLoading }

        XCTAssertNotNil(chat.error)
        XCTAssertFalse(chat.isLoading)
    }

    @MainActor
    func testStopCancelsInFlightStreamAndKeepsPartialMessage() async {
        let model = ControlledStreamModel(
            chunks: [
                AIStreamChunk(text: "Partial"),
                AIStreamChunk(text: " ignored")
            ],
            delay: .milliseconds(100)
        )
        let chat = AIChat(model: model)
        chat.input = "Hi"

        chat.send()
        await waitUntil { chat.messages.last?.content == "Partial" }

        chat.stop()

        XCTAssertFalse(chat.isLoading)
        XCTAssertEqual(chat.messages.last?.content, "Partial")
        XCTAssertNil(chat.error)
    }

    @MainActor
    func testResetClearsStateAndCancelsInFlightStream() async {
        let model = ControlledStreamModel(chunks: [AIStreamChunk(text: "Partial")], delay: .milliseconds(100))
        let chat = AIChat(model: model)
        chat.input = "Hi"
        chat.error = AIError.invalidResponse

        chat.send()
        await waitUntil { chat.messages.count == 2 }

        chat.reset()

        XCTAssertTrue(chat.messages.isEmpty)
        XCTAssertEqual(chat.input, "")
        XCTAssertFalse(chat.isLoading)
        XCTAssertNil(chat.error)
    }

    @MainActor
    func testSystemPromptAndHistoryArePassedToModel() async {
        let model = ControlledStreamModel(chunks: [AIStreamChunk(text: "Ok")])
        let chat = AIChat(model: model, systemPrompt: "Be concise.", maxMessages: 3)
        chat.messages = [
            ChatMessage(role: .user, content: "Old"),
            ChatMessage(role: .assistant, content: "Old reply")
        ]
        chat.input = "New"

        chat.send()
        await waitUntil { !chat.isLoading }

        let captured = await model.capturedMessages
        XCTAssertEqual(captured.first?.role, .system)
        XCTAssertEqual(captured.first?.content, "Be concise.")
        XCTAssertEqual(captured.last?.role, .user)
        XCTAssertEqual(captured.last?.content, "New")
        XCTAssertLessThanOrEqual(captured.count, 3)
    }
}

private final class ControlledStreamModel: AIStreamModel, @unchecked Sendable {
    private let chunks: [AIStreamChunk]
    private let error: Error?
    private let delay: Duration
    private let state = ControlledStreamModelState()

    init(chunks: [AIStreamChunk], error: Error? = nil, delay: Duration = .milliseconds(0)) {
        self.chunks = chunks
        self.error = error
        self.delay = delay
    }

    var capturedMessages: [ChatMessage] {
        get async {
            await state.capturedMessages
        }
    }

    func generate(_ prompt: String) async throws -> AIResponse {
        AIResponse(text: "")
    }

    func stream(_ prompt: String) -> AsyncThrowingStream<AIStreamChunk, Error> {
        stream(messages: [ChatMessage(role: .user, content: prompt)])
    }

    func stream(messages: [ChatMessage]) -> AsyncThrowingStream<AIStreamChunk, Error> {
        stream(messages: messages, options: GenerationOptions())
    }

    func stream(messages: [ChatMessage], options: GenerationOptions) -> AsyncThrowingStream<AIStreamChunk, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                await state.capture(messages)

                if let error {
                    continuation.finish(throwing: error)
                    return
                }

                for chunk in chunks {
                    if Task.isCancelled {
                        continuation.finish(throwing: CancellationError())
                        return
                    }
                    continuation.yield(chunk)
                    try? await Task.sleep(for: delay)
                }

                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}

private actor ControlledStreamModelState {
    private(set) var capturedMessages: [ChatMessage] = []

    func capture(_ messages: [ChatMessage]) {
        capturedMessages = messages
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
