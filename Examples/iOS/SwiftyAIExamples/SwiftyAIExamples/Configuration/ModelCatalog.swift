import Foundation

struct ModelOption: Identifiable, Hashable {
    let provider: AIProvider
    let name: String
    let label: String

    var id: String { "\(provider.rawValue)-\(name)" }
}

enum ModelCatalog {
    static let options: [ModelOption] = [
        .init(provider: .openAI, name: "gpt-4o-mini", label: "GPT-4o mini"),
        .init(provider: .anthropic, name: "claude-3-5-haiku-latest", label: "Claude 3.5 Haiku"),
        .init(provider: .gemini, name: "gemini-1.5-flash", label: "Gemini 1.5 Flash"),
        .init(provider: .groq, name: "llama-3.1-8b-instant", label: "Llama 3.1 8B Instant"),
        .init(provider: .openRouter, name: "openai/gpt-4o-mini", label: "OpenAI GPT-4o mini"),
        .init(provider: .mistral, name: "mistral-small-latest", label: "Mistral Small"),
        .init(provider: .cohere, name: "command-r", label: "Command R"),
        .init(provider: .cloudflare, name: "@cf/meta/llama-3.1-8b-instruct", label: "Llama 3.1 8B"),
        .init(provider: .ollama, name: "llama3.2", label: "Llama 3.2")
    ]

    static func options(for provider: AIProvider) -> [ModelOption] {
        options.filter { $0.provider == provider }
    }

    static func defaultModel(for provider: AIProvider) -> String {
        options(for: provider).first?.name ?? ""
    }
}
