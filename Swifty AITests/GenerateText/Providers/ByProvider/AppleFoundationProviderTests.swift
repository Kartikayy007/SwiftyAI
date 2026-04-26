import XCTest

@testable import Swifty_AI

#if canImport(FoundationModels)
    import FoundationModels

    @available(iOS 26, macOS 26, *)
    final class AppleFoundationProviderTests: XCTestCase {
        func testIsAvailableReturnsBool() {
            let _ = AppleFoundationProvider.isAvailable
        }

        func testConformsToAIModel() throws {
            guard AppleFoundationProvider.isAvailable else {
                throw XCTSkip("Apple Intelligence not available on this device.")
            }
            let provider: any AIModel = AppleFoundationProvider()
            XCTAssertNotNil(provider)
        }

        func testLiveGeneration() async throws {
            guard AppleFoundationProvider.isAvailable else {
                throw XCTSkip("Apple Intelligence not available on this device.")
            }
            let provider = AppleFoundationProvider()
            let response = try await provider.generate("Reply with exactly: ok")
            XCTAssertFalse(response.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            XCTAssertEqual(response.model, "apple-on-device")
        }
    }
#endif
