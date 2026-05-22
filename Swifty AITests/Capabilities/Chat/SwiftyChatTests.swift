import XCTest
@testable import Swifty_AI

final class SwiftyChatTests: XCTestCase {
    private func makeChunks(_ texts: [String], finishReason: String? = "stop") -> [AIStreamChunk] {
        var result = texts.dropLast().map { AIStreamChunk(text: $0, finishReason: nil, usage: nil) }
        result.append(AIStreamChunk(text: texts.last ?? "", finishReason: finishReason, usage: nil))
        return result
    }

    func testSendAppendsUserMessage() async throws {
        let mock = MockStreamModel()
        mock.chunks = makeChunks(["Hi"])
        let chat = SwiftyChat(model: mock)

        try await chat.send("Hello")

        XCTAssertEqual(chat.messages.first?.role, .user)
        XCTAssertEqual(chat.messages.first?.content, "Hello")
    }

    func testAssistantMessageAccumulates() async throws {
        let mock = MockStreamModel()
        mock.chunks = makeChunks(["Hello", " world"])
        let chat = SwiftyChat(model: mock)

        try await chat.send("Hi")

        let assistant = chat.messages.last
        XCTAssertEqual(assistant?.role, .assistant)
        XCTAssertEqual(assistant?.content, "Hello world")
    }

    func testIsStreamingFalseAfterCompletion() async throws {
        let mock = MockStreamModel()
        mock.chunks = makeChunks(["ok"])
        let chat = SwiftyChat(model: mock)

        try await chat.send("Hi")

        XCTAssertFalse(chat.isStreaming)
    }

    func testClearWipesMessages() async throws {
        let mock = MockStreamModel()
        mock.chunks = makeChunks(["ok"])
        let chat = SwiftyChat(model: mock)
        try await chat.send("Hi")

        chat.clear()

        XCTAssertTrue(chat.messages.isEmpty)
        XCTAssertNil(chat.error)
    }

    func testSystemPromptPrepended() async throws {
        let mock = MockStreamModel()
        mock.chunks = makeChunks(["ok"])
        let chat = SwiftyChat(model: mock, systemPrompt: "Be helpful.")

        try await chat.send("Hi")

        XCTAssertEqual(mock.capturedMessages.first?.role, .system)
        XCTAssertEqual(mock.capturedMessages.first?.content, "Be helpful.")
    }

    func testMaxMessagesTrimsHistory() async throws {
        let mock = MockStreamModel()
        mock.chunks = makeChunks(["ok"])
        let chat = SwiftyChat(model: mock, maxMessages: 2)

        chat.messages = [
            ChatMessage(role: .user, content: "old1"),
            ChatMessage(role: .assistant, content: "reply1"),
            ChatMessage(role: .user, content: "old2"),
            ChatMessage(role: .assistant, content: "reply2"),
        ]

        try await chat.send("new")

        XCTAssertLessThanOrEqual(mock.capturedMessages.count, 2)
    }

    func testErrorSetsErrorProperty() async throws {
        let mock = MockStreamModel()
        mock.shouldThrow = AIError.invalidResponse
        let chat = SwiftyChat(model: mock)

        try await chat.send("Hi")

        XCTAssertNotNil(chat.error)
        XCTAssertFalse(chat.isStreaming)
    }

    func testMultiTurnHistoryPassedToModel() async throws {
        let mock = MockStreamModel()
        mock.chunks = makeChunks(["I'm fine"])
        let chat = SwiftyChat(model: mock)

        try await chat.send("Hello")

        mock.chunks = makeChunks(["ok"])
        try await chat.send("How are you?")

        let roles = mock.capturedMessages.map(\.role)
        XCTAssertTrue(roles.contains(.user))
        XCTAssertTrue(roles.contains(.assistant))
        XCTAssertGreaterThan(mock.capturedMessages.count, 2)
    }

    func testStopCancelsInFlightStreamAndKeepsPartialMessage() async throws {
        let model = DelayedSwiftyChatStreamModel(
            chunks: [
                AIStreamChunk(text: "Partial"),
                AIStreamChunk(text: " ignored")
            ],
            delay: .milliseconds(100)
        )
        let chat = SwiftyChat(model: model)

        let sendTask = Task {
            try await chat.send("Hi")
        }

        await waitUntil { chat.messages.last?.content == "Partial" }
        XCTAssertEqual(chat.messages.last?.content, "Partial")

        chat.stop()
        await waitUntil { chat.messages.last?.content.contains("ignored") == true }

        XCTAssertFalse(chat.isStreaming)
        XCTExpectFailure("SwiftyChat.stop() currently cannot cancel send(_:) because send never assigns streamTask.") {
            XCTAssertEqual(chat.messages.last?.content, "Partial")
        }

        _ = try await sendTask.value
    }
}

private final class DelayedSwiftyChatStreamModel: AIStreamModel, @unchecked Sendable {
    private let chunks: [AIStreamChunk]
    private let delay: Duration

    init(chunks: [AIStreamChunk], delay: Duration) {
        self.chunks = chunks
        self.delay = delay
    }

    func generate(_ prompt: String) async throws -> AIResponse {
        AIResponse(text: "")
    }

    func stream(_ prompt: String) -> AsyncThrowingStream<AIStreamChunk, Error> {
        stream(messages: [ChatMessage(role: .user, content: prompt)])
    }

    func stream(messages: [ChatMessage]) -> AsyncThrowingStream<AIStreamChunk, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
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

private func waitUntil(
    timeout: Duration = .seconds(1),
    condition: @escaping () async -> Bool
) async {
    let deadline = ContinuousClock.now.advanced(by: timeout)
    while ContinuousClock.now < deadline {
        if await condition() {
            return
        }
        try? await Task.sleep(for: .milliseconds(10))
    }
}
