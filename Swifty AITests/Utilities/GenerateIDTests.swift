import Foundation
import XCTest
@testable import Swifty_AI

final class GenerateIDTests: XCTestCase {
    func testGenerateIdReturnsUUIDString() {
        let id = generateId()

        XCTAssertNotNil(UUID(uuidString: id))
    }

    func testGenerateIdIsUnique() {
        let ids = (0..<10_000).map { _ in generateId() }

        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testGenerateIdWithPrefixUsesUnderscoreSeparator() {
        let id = generateId(prefix: "msg")

        XCTAssertTrue(id.hasPrefix("msg_"))
        XCTAssertNotNil(UUID(uuidString: String(id.dropFirst("msg_".count))))
    }

    func testGenerateIdPreservesPrefix() {
        let id = generateId(prefix: "tool.call")

        XCTAssertTrue(id.hasPrefix("tool.call_"))
    }
}
