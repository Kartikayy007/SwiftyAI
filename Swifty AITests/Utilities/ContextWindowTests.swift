import Foundation
import XCTest
@testable import Swifty_AI

final class ContextWindowTests: XCTestCase {
    func testEstimatedTokensForTextUsesApproximateCharacterCount() {
        let window = ContextWindow(maxTokens: 100)

        XCTAssertEqual(window.estimatedTokens(for: ""), 0)
        XCTAssertEqual(window.estimatedTokens(for: "abc"), 1)
        XCTAssertEqual(window.estimatedTokens(for: "1234567890123456"), 4)
    }

    func testRemainingBudgetSubtractsEstimatedMessages() {
        let window = ContextWindow(maxTokens: 10)
        let messages = [ChatMessage(role: .user, content: "1234567890123456")]

        XCTAssertEqual(window.remaining(for: messages), 5)
    }

    func testRemainingBudgetClampsAtZero() {
        let window = ContextWindow(maxTokens: 1)
        let messages = [ChatMessage(role: .user, content: String(repeating: "a", count: 100))]

        XCTAssertEqual(window.remaining(for: messages), 0)
    }

    func testWarningThreshold() {
        let message = ChatMessage(role: .user, content: "1234567890123456")

        XCTAssertFalse(ContextWindow(maxTokens: 6, warningThreshold: 1).isNearLimit(for: [message]))
        XCTAssertTrue(ContextWindow(maxTokens: 5, warningThreshold: 1).isNearLimit(for: [message]))
    }

    func testMultipartMessagesCountAttachments() {
        let window = ContextWindow(maxTokens: 1_000)
        let message = ChatMessage(role: .user, parts: [
            .text("abcd"),
            .fileData(Data("hello".utf8), mediaType: .plainText, filename: "note.txt"),
        ])

        XCTAssertEqual(window.estimatedTokens(for: [message]), 258)
    }
}
