import Foundation
import SwiftyAI

enum SwiftyAIConfigurator {
    static func configureRegistry(settings: ProviderSettings, apiKey: String) {
        AI.configure { configuration in
            switch settings.provider {
            case .openAI:
                configuration.openAI(apiKey: apiKey)
            case .anthropic:
                configuration.anthropic(apiKey: apiKey)
            case .gemini:
                configuration.gemini(apiKey: apiKey)
            case .groq:
                configuration.groq(apiKey: apiKey)
            case .openRouter:
                configuration.openRouter(apiKey: apiKey)
            case .mistral:
                configuration.mistral(apiKey: apiKey)
            case .cohere:
                configuration.cohere(apiKey: apiKey)
            case .cloudflare:
                configuration.cloudflare(accountID: settings.accountID, apiKey: apiKey)
            case .ollama:
                configuration.ollama(baseURL: settings.ollamaBaseURL)
            }
        }
    }
}

enum ModelFactory {
    static func makeStreamModel(settings: ProviderSettings, apiKey: String) throws -> any AIStreamModel {
        try validate(settings: settings, apiKey: apiKey)

        switch settings.provider {
        case .openAI:
            return OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: apiKey, model: settings.model)
        case .anthropic:
            return AnthropicProvider(apiKey: apiKey, model: settings.model)
        case .gemini:
            return GeminiProvider(apiKey: apiKey, model: settings.model)
        case .groq:
            return OpenAICompatibleProvider(baseURL: "https://api.groq.com/openai/v1", apiKey: apiKey, model: settings.model)
        case .openRouter:
            return OpenAICompatibleProvider(baseURL: "https://openrouter.ai/api/v1", apiKey: apiKey, model: settings.model)
        case .mistral:
            return OpenAICompatibleProvider(baseURL: "https://api.mistral.ai/v1", apiKey: apiKey, model: settings.model)
        case .cohere:
            return OpenAICompatibleProvider(baseURL: "https://api.cohere.com/compatibility/v1", apiKey: apiKey, model: settings.model)
        case .cloudflare:
            let baseURL = "https://api.cloudflare.com/client/v4/accounts/\(settings.accountID)/ai/v1"
            return OpenAICompatibleProvider(baseURL: baseURL, apiKey: apiKey, model: settings.model)
        case .ollama:
            return OpenAICompatibleProvider(baseURL: settings.ollamaBaseURL, apiKey: "ollama", model: settings.model)
        }
    }

    static func makeToolModel(settings: ProviderSettings, apiKey: String) throws -> any AIToolCallingModel {
        guard let model = try makeStreamModel(settings: settings, apiKey: apiKey) as? any AIToolCallingModel else {
            throw ExampleError.message("The selected provider does not support tool calling.")
        }
        return model
    }

    static func validate(settings: ProviderSettings, apiKey: String) throws {
        if settings.provider.requiresAPIKey && apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ExampleError.message("Add an API key in Settings before running this example.")
        }
        if settings.provider.requiresAccountID && settings.accountID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ExampleError.message("Add a Cloudflare account ID in Settings before running this example.")
        }
        if settings.model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ExampleError.message("Choose or enter a model before running this example.")
        }
    }
}
