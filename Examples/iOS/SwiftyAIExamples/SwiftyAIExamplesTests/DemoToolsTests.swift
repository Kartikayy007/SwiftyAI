import XCTest
@testable import SwiftyAIExamples

final class DemoToolsTests: XCTestCase {
    func testCalculateTipReturnsTipAndTotal() async throws {
        let tool = try XCTUnwrap(DemoTools.all.first { $0.name == "calculate_tip" })
        let result = try await tool.execute(["bill": 100.0, "percent": 20.0])

        XCTAssertTrue(result.contains("tip 20.00"))
        XCTAssertTrue(result.contains("total 120.00"))
    }

    func testLookupDemoOrderReturnsStatus() async throws {
        let tool = try XCTUnwrap(DemoTools.all.first { $0.name == "lookup_demo_order" })
        let result = try await tool.execute(["orderID": "B200"])

        XCTAssertTrue(result.contains("out for delivery"))
    }
}
