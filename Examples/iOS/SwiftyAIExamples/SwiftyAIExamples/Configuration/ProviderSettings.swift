import Foundation

enum AIProvider: String, CaseIterable, Codable, Identifiable {
    case openAI
    case anthropic
    case gemini
    case groq
    case openRouter
    case mistral
    case cohere
    case cloudflare
    case ollama

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openAI: "OpenAI"
        case .anthropic: "Anthropic"
        case .gemini: "Gemini"
        case .groq: "Groq"
        case .openRouter: "OpenRouter"
        case .mistral: "Mistral"
        case .cohere: "Cohere"
        case .cloudflare: "Cloudflare Workers AI"
        case .ollama: "Ollama"
        }
    }

    var registryPrefix: String {
        switch self {
        case .openAI: "openai"
        case .anthropic: "anthropic"
        case .gemini: "gemini"
        case .groq: "groq"
        case .openRouter: "openrouter"
        case .mistral: "mistral"
        case .cohere: "cohere"
        case .cloudflare: "cloudflare"
        case .ollama: "ollama"
        }
    }

    var requiresAPIKey: Bool { self != .ollama }
    var requiresAccountID: Bool { self == .cloudflare }
    var supportsBaseURL: Bool { self == .ollama }
}

struct ProviderSettings: Codable, Equatable {
    var provider: AIProvider
    var model: String
    var accountID: String
    var ollamaBaseURL: String

    init(
        provider: AIProvider = .openAI,
        model: String = ModelCatalog.defaultModel(for: .openAI),
        accountID: String = "",
        ollamaBaseURL: String = "http://localhost:11434/v1"
    ) {
        self.provider = provider
        self.model = model
        self.accountID = accountID
        self.ollamaBaseURL = ollamaBaseURL
    }

    var modelString: String {
        "\(provider.registryPrefix)/\(model)"
    }
}
