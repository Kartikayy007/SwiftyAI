import Foundation

public final class AIConfiguration {
    private let registry: AIRegistry

    init(registry: AIRegistry) {
        self.registry = registry
    }

    public func openAI(apiKey: String) {
        Task { await registry.set(.apiKey(apiKey), for: "openai") }
    }

    public func anthropic(apiKey: String) {
        Task { await registry.set(.apiKey(apiKey), for: "anthropic") }
    }

    public func gemini(apiKey: String) {
        Task { await registry.set(.apiKey(apiKey), for: "gemini") }
    }

    public func groq(apiKey: String) {
        Task { await registry.set(.apiKey(apiKey), for: "groq") }
    }

    public func openRouter(apiKey: String) {
        Task { await registry.set(.apiKey(apiKey), for: "openrouter") }
    }

    public func mistral(apiKey: String) {
        Task { await registry.set(.apiKey(apiKey), for: "mistral") }
    }

    public func cohere(apiKey: String) {
        Task { await registry.set(.apiKey(apiKey), for: "cohere") }
    }

    public func cloudflare(accountID: String, apiKey: String) {
        Task { await registry.set(.cloudflare(accountID: accountID, apiKey: apiKey), for: "cloudflare") }
    }

    public func ollama(baseURL: String = "http://localhost:11434/v1") {
        Task { await registry.set(.ollama(baseURL: baseURL), for: "ollama") }
    }
}
