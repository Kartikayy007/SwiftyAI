import XCTest
@testable import SwiftyAIExamples

final class ModelCatalogTests: XCTestCase {
    func testEveryProviderHasDefaultModel() {
        for provider in AIProvider.allCases {
            XCTAssertFalse(ModelCatalog.defaultModel(for: provider).isEmpty, "\(provider.displayName) needs a default model")
        }
    }

    func testModelStringUsesRegistryPrefix() {
        let settings = ProviderSettings(provider: .openAI, model: "gpt-4o-mini")
        XCTAssertEqual(settings.modelString, "openai/gpt-4o-mini")
    }
}
