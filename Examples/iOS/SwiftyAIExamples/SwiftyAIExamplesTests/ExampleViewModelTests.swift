import XCTest
@testable import SwiftyAIExamples

final class ExampleViewModelTests: XCTestCase {
    @MainActor
    func testProviderValidationRequiresAPIKey() {
        XCTAssertThrowsError(
            try ModelFactory.validate(settings: ProviderSettings(provider: .openAI, model: "gpt-4o-mini"), apiKey: "")
        )
    }

    @MainActor
    func testProviderValidationAllowsOllamaWithoutAPIKey() {
        XCTAssertNoThrow(
            try ModelFactory.validate(settings: ProviderSettings(provider: .ollama, model: "llama3.2"), apiKey: "")
        )
    }
}
