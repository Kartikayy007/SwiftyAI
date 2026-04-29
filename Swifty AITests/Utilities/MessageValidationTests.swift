import Foundation
import XCTest
@testable import Swifty_AI

final class MessageValidationTests: XCTestCase {
    func testAcceptsValidMessages() throws {
        let messages = [
            ChatMessage(role: .system, content: "Be concise."),
            ChatMessage(role: .user, content: "Hello"),
            ChatMessage(role: .assistant, content: "Hi"),
        ]

        XCTAssertNoThrow(try validateUIMessages(messages))
    }

    func testAcceptsMultipartMessages() throws {
        let message = ChatMessage(role: .user, parts: [
            .text("Describe this"),
            .imageURL(URL(string: "https://example.com/image.png")!),
        ])

        XCTAssertNoThrow(try validateUIMessages([message]))
    }

    func testRejectsEmptyConversation() {
        XCTAssertThrowsError(try validateUIMessages([])) { error in
            XCTAssertEqual(error as? UIMessageValidationError, .emptyConversation)
        }
    }

    func testRejectsDuplicateIds() {
        let messages = [
            ChatMessage(id: "same", role: .user, content: "Hello"),
            ChatMessage(id: "same", role: .assistant, content: "Hi"),
        ]

        XCTAssertThrowsError(try validateUIMessages(messages)) { error in
            XCTAssertEqual(error as? UIMessageValidationError, .duplicateId("same"))
        }
    }

    func testRejectsEmptyContent() {
        let message = ChatMessage(id: "empty", role: .user, content: "   ")

        XCTAssertThrowsError(try validateUIMessages([message])) { error in
            XCTAssertEqual(error as? UIMessageValidationError, .emptyContent(messageId: "empty"))
        }
    }

    func testRejectsEmptyAttachmentPayload() {
        let message = ChatMessage(id: "empty-file", role: .user, parts: [
            .fileData(Data(), mediaType: .plainText, filename: "empty.txt"),
        ])

        XCTAssertThrowsError(try validateUIMessages([message])) { error in
            XCTAssertEqual(error as? UIMessageValidationError, .emptyContent(messageId: "empty-file"))
        }
    }
}
