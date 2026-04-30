import XCTest
@testable import SwiftyAIExamples

final class AppRouteTests: XCTestCase {
    func testNewSDKFeatureRoutesAreAvailable() {
        XCTAssertTrue(AppRoute.allCases.contains(.aiChatHook))
        XCTAssertTrue(AppRoute.allCases.contains(.aiCompletionHook))
        XCTAssertTrue(AppRoute.allCases.contains(.embeddings))
    }
}
