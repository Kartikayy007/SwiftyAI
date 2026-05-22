import XCTest
@testable import Swifty_AI

final class ProviderFactoryTests: XCTestCase {
    func testAIModelFactoriesReturnExpectedProviderTypes() {
        let openAI: OpenAICompatibleProvider = .openAI(apiKey: "openai", model: "gpt-4o-mini")
        let groq: OpenAICompatibleProvider = .groq(apiKey: "groq", model: "llama-3.3-70b-versatile")
        let openRouter: OpenAICompatibleProvider = .openRouter(apiKey: "openrouter", model: "openai/gpt-4o-mini")
        let mistral: OpenAICompatibleProvider = .mistral(apiKey: "mistral", model: "mistral-small-latest")
        let cohere: OpenAICompatibleProvider = .cohere(apiKey: "cohere", model: "command-a-03-2025")
        let cloudflare: OpenAICompatibleProvider = .cloudflare(accountID: "account", apiKey: "cloudflare", model: "@cf/meta/llama-3.1-8b-instruct")
        let ollama: OpenAICompatibleProvider = .ollama(model: "llama3.2")
        let anthropic: AnthropicProvider = .anthropic(apiKey: "anthropic", model: "claude-haiku-4-5-20251001")
        let gemini: GeminiProvider = .gemini(apiKey: "gemini", model: "gemini-2.5-flash")

        XCTAssertEqual(openAI.baseURL, "https://api.openai.com/v1")
        XCTAssertEqual(groq.baseURL, "https://api.groq.com/openai/v1")
        XCTAssertEqual(openRouter.baseURL, "https://openrouter.ai/api/v1")
        XCTAssertEqual(mistral.baseURL, "https://api.mistral.ai/v1")
        XCTAssertEqual(cohere.baseURL, "https://api.cohere.com/compatibility/v1")
        XCTAssertEqual(cloudflare.baseURL, "https://api.cloudflare.com/client/v4/accounts/account/ai/v1")
        XCTAssertEqual(ollama.baseURL, "http://localhost:11434/v1")
        XCTAssertEqual(openAI.model, "gpt-4o-mini")
        XCTAssertEqual(groq.model, "llama-3.3-70b-versatile")
        XCTAssertEqual(String(describing: type(of: anthropic)), "AnthropicProvider")
        XCTAssertEqual(gemini.model, "gemini-2.5-flash")
    }

    func testAIStreamModelFactoriesReturnExpectedProviderTypes() {
        let openAI: OpenAICompatibleProvider = .openAI(apiKey: "openai", model: "gpt-4o-mini")
        let anthropic: AnthropicProvider = .anthropic(apiKey: "anthropic", model: "claude-haiku-4-5-20251001")
        let gemini: GeminiProvider = .gemini(apiKey: "gemini", model: "gemini-2.5-flash")

        let streamModels: [any AIStreamModel] = [openAI, anthropic, gemini]
        XCTAssertEqual(streamModels.count, 3)
    }

    func testOpenAICompatibleProviderTypealiasesCompile() {
        let openAI: OpenAIProvider = OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: "key", model: "model")
        let groq: GroqProvider = OpenAICompatibleProvider(baseURL: "https://api.groq.com/openai/v1", apiKey: "key", model: "model")
        let openRouter: OpenRouterProvider = OpenAICompatibleProvider(baseURL: "https://openrouter.ai/api/v1", apiKey: "key", model: "model")
        let mistral: MistralProvider = OpenAICompatibleProvider(baseURL: "https://api.mistral.ai/v1", apiKey: "key", model: "model")
        let cohere: CohereProvider = OpenAICompatibleProvider(baseURL: "https://api.cohere.com/compatibility/v1", apiKey: "key", model: "model")
        let cloudflare: CloudflareProvider = OpenAICompatibleProvider(baseURL: "https://api.cloudflare.com/client/v4/accounts/account/ai/v1", apiKey: "key", model: "model")
        let ollama: OllamaProvider = OpenAICompatibleProvider(baseURL: "http://localhost:11434/v1", apiKey: "ollama", model: "model")

        XCTAssertEqual(openAI.baseURL, "https://api.openai.com/v1")
        XCTAssertEqual(groq.baseURL, "https://api.groq.com/openai/v1")
        XCTAssertEqual(openRouter.baseURL, "https://openrouter.ai/api/v1")
        XCTAssertEqual(mistral.baseURL, "https://api.mistral.ai/v1")
        XCTAssertEqual(cohere.baseURL, "https://api.cohere.com/compatibility/v1")
        XCTAssertEqual(cloudflare.baseURL, "https://api.cloudflare.com/client/v4/accounts/account/ai/v1")
        XCTAssertEqual(ollama.baseURL, "http://localhost:11434/v1")
    }
}
