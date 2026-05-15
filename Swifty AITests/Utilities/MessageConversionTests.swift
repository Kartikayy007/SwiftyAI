import Foundation
import XCTest
@testable import Swifty_AI

final class MessageConversionTests: XCTestCase {
    func testConvertsTextMessages() throws {
        let messages = [
            ChatMessage(id: "user", role: .user, content: "Hello"),
            ChatMessage(id: "assistant", role: .assistant, content: "Hi"),
        ]

        let converted = try convertToModelMessages(messages)

        XCTAssertEqual(converted.map(\.id), ["user", "assistant"])
        XCTAssertEqual(converted.map(\.role), [.user, .assistant])
        XCTAssertEqual(converted.map(\.content), ["Hello", "Hi"])
    }

    func testPreservesSystemMessages() throws {
        let messages = [
            ChatMessage(id: "system", role: .system, content: "Be concise."),
            ChatMessage(id: "user", role: .user, content: "Hello"),
        ]

        let converted = try convertToModelMessages(messages)

        XCTAssertEqual(converted.first?.role, .system)
        XCTAssertEqual(converted.first?.content, "Be concise.")
    }

    func testPreservesMultipartMessages() throws {
        let messages = [
            ChatMessage(id: "user", role: .user, parts: [
                .text("Analyze"),
                .pdfData(Data("pdf".utf8), filename: "doc.pdf"),
            ]),
        ]

        let converted = try convertToModelMessages(messages)

        XCTAssertEqual(converted.first?.parts.count, 2)
        XCTAssertEqual(converted.first?.parts.first?.textValue, "Analyze")
        XCTAssertEqual(converted.first?.parts.last?.filename, "doc.pdf")
    }

    func testInvalidMessagesThrowBeforeConversion() {
        let messages = [ChatMessage(id: "empty", role: .assistant, content: "")]

        XCTAssertThrowsError(try convertToModelMessages(messages)) { error in
            XCTAssertEqual(error as? UIMessageValidationError, .emptyContent(messageId: "empty"))
        }
    }
}
