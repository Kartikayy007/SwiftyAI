import Foundation

public final class AIConfiguration {
    private let registry: AIRegistry

    init(registry: AIRegistry) {
        self.registry = registry
    }

    public func openAI(apiKey: String) {
        registry.set(.apiKey(apiKey), for: "openai")
    }

    public func anthropic(apiKey: String) {
        registry.set(.apiKey(apiKey), for: "anthropic")
    }

    public func gemini(apiKey: String) {
        registry.set(.apiKey(apiKey), for: "gemini")
    }

    public func groq(apiKey: String) {
        registry.set(.apiKey(apiKey), for: "groq")
    }

    public func openRouter(apiKey: String) {
        registry.set(.apiKey(apiKey), for: "openrouter")
    }

    public func mistral(apiKey: String) {
        registry.set(.apiKey(apiKey), for: "mistral")
    }

    public func cohere(apiKey: String) {
        registry.set(.apiKey(apiKey), for: "cohere")
    }

    public func cloudflare(accountID: String, apiKey: String) {
        registry.set(.cloudflare(accountID: accountID, apiKey: apiKey), for: "cloudflare")
    }

    public func ollama(baseURL: String = "http://localhost:11434/v1") {
        registry.set(.ollama(baseURL: baseURL), for: "ollama")
    }

    #if canImport(FoundationModels)
    @available(iOS 26, macOS 26, *)
    public func appleFoundation() {
        registry.set(.appleFoundation, for: "applefoundation")
    }
    #endif
}
