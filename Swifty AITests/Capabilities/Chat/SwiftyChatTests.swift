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
}
