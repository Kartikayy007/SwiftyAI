import XCTest
@testable import Swifty_AI

final class AllStreamProvidersTests: XCTestCase {
    static override var defaultTestSuite: XCTestSuite {
        let suite = XCTestSuite(name: "AllStreamProviders")
        suite.addTest(OpenAIStreamTests.defaultTestSuite)
        suite.addTest(AnthropicStreamTests.defaultTestSuite)
        suite.addTest(GeminiStreamTests.defaultTestSuite)
        suite.addTest(GroqStreamTests.defaultTestSuite)
        suite.addTest(OpenRouterStreamTests.defaultTestSuite)
        suite.addTest(MistralStreamTests.defaultTestSuite)
        suite.addTest(CohereStreamTests.defaultTestSuite)
        suite.addTest(CloudflareStreamTests.defaultTestSuite)
        suite.addTest(OllamaStreamTests.defaultTestSuite)
        return suite
    }
}
