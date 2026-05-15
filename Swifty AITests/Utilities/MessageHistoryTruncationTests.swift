import XCTest
@testable import Swifty_AI

final class MessageHistoryTruncationTests: XCTestCase {
    func testLastMessagesStrategyUsesPruningRules() {
        let truncated = truncateMessages(makeConversation(), strategy: .lastMessages(2))

        XCTAssertEqual(truncated.map(\.content), ["system", "new"])
    }

    func testPreserveSystemAndLastUserStrategy() {
        let truncated = truncateMessages(makeConversation(), strategy: .preserveSystemAndLastUser)

        XCTAssertEqual(truncated.map(\.content), ["system", "new"])
    }

    func testApproximateTokensStrategyReducesHistory() {
        let messages = makeConversation()
        let truncated = truncateMessages(
            messages,
            strategy: .approximateTokens(12),
            contextWindow: ContextWindow(maxTokens: 100)
        )

        XCTAssertLessThan(truncated.count, messages.count)
        XCTAssertEqual(truncated.first?.content, "system")
        XCTAssertTrue(truncated.contains(where: { $0.role == .user && $0.content == "new" }))
    }

    func testEveryStrategyPreservesValidConversationShape() {
        let messages = makeConversation()
        let strategies: [MessageHistoryTruncationStrategy] = [
            .lastMessages(3),
            .approximateTokens(12),
            .preserveSystemAndLastUser,
        ]

        for strategy in strategies {
            let truncated = truncateMessages(messages, strategy: strategy, contextWindow: ContextWindow(maxTokens: 100))
            XCTAssertNoThrow(try validateUIMessages(truncated))
        }
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
