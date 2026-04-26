import XCTest
@testable import Swifty_AI

final class AllProvidersTests: XCTestCase {
    static override var defaultTestSuite: XCTestSuite {
        let suite = XCTestSuite(name: "AllProviders")
        suite.addTest(OpenAIProviderTests.defaultTestSuite)
        suite.addTest(AnthropicProviderTests.defaultTestSuite)
        suite.addTest(GeminiProviderTests.defaultTestSuite)
        suite.addTest(GroqProviderTests.defaultTestSuite)
        suite.addTest(OpenRouterProviderTests.defaultTestSuite)
        suite.addTest(MistralProviderTests.defaultTestSuite)
        suite.addTest(CohereProviderTests.defaultTestSuite)
        suite.addTest(CloudflareProviderTests.defaultTestSuite)
        suite.addTest(OllamaProviderTests.defaultTestSuite)
        return suite
    }
}
