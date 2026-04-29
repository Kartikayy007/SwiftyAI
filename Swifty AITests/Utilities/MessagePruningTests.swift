import XCTest
@testable import Swifty_AI

final class MessagePruningTests: XCTestCase {
    func testPreservesSystemAndLatestUser() {
        let messages = makeConversation()

        let pruned = pruneMessages(messages, maxMessages: 2)

        XCTAssertEqual(pruned.first?.role, .system)
        XCTAssertEqual(pruned.last?.content, "new")
    }

    func testKeepsRecentMessages() {
        let messages = makeConversation()

        let pruned = pruneMessages(messages, maxMessages: 4)

        XCTAssertEqual(pruned.map(\.content), ["system", "old assistant", "new", "new assistant"])
    }

    func testHandlesTinyLimits() {
        let messages = makeConversation()

        let pruned = pruneMessages(messages, maxMessages: 0)

        XCTAssertEqual(pruned.map(\.content), ["system", "new"])
    }

    func testFallsBackToLatestMessageWhenNoSystemOrUserExists() {
        let messages = [
            ChatMessage(role: .assistant, content: "a"),
            ChatMessage(role: .assistant, content: "b"),
        ]

        let pruned = pruneMessages(messages, maxMessages: 0)

        XCTAssertEqual(pruned.map(\.content), ["b"])
    }

    func testPrunedMessagesRemainValid() throws {
        let pruned = pruneMessages(makeConversation(), maxMessages: 3)

        XCTAssertNoThrow(try validateUIMessages(pruned))
    }

    private func makeConversation() -> [ChatMessage] {
        [
            ChatMessage(role: .system, content: "system"),
            ChatMessage(role: .user, content: "old user"),
            ChatMessage(role: .assistant, content: "old assistant"),
            ChatMessage(role: .user, content: "new"),
            ChatMessage(role: .assistant, content: "new assistant"),
        ]
    }
}
