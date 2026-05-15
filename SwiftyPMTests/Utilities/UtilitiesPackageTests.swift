import XCTest
import SwiftyAI

final class UtilitiesPackageTests: XCTestCase {
    func testGenerateIdIsAvailableFromPackageProduct() {
        let id = generateId(prefix: "msg")

        XCTAssertTrue(id.hasPrefix("msg_"))
    }

    func testStreamingUtilitiesAreAvailableFromPackageProduct() async throws {
        var chunks: [String] = []

        for try await chunk in simulateReadableStream("Hello", chunkSize: 2) {
            chunks.append(chunk)
        }

        XCTAssertEqual(chunks, ["He", "ll", "o"])
    }

    func testContextWindowIsAvailableFromPackageProduct() {
        let window = ContextWindow(maxTokens: 10)
        let remaining = window.remaining(for: [
            ChatMessage(role: .user, content: "1234567890123456"),
        ])

        XCTAssertEqual(remaining, 5)
    }
}
