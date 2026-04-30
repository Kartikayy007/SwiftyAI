import Foundation

actor AIRegistry {
    static let shared = AIRegistry()

    enum ProviderConfig {
        case apiKey(String)
        case cloudflare(accountID: String, apiKey: String)
        case ollama(baseURL: String)
    }

    private var configs: [String: ProviderConfig] = [:]

    func set(_ config: ProviderConfig, for provider: String) {
        configs[provider] = config
    }

    func resolve(_ modelString: String) throws -> any AIStreamModel {
        let parts = modelString.split(separator: "/", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { throw AIError.invalidModelString(modelString) }
        let provider = parts[0].lowercased()
        let model = parts[1]

        switch provider {
        case "openai":
            guard case .apiKey(let key) = configs["openai"] else {
                throw AIError.providerNotConfigured("openai")
            }
            return OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: key, model: model)
        case "anthropic":
            guard case .apiKey(let key) = configs["anthropic"] else {
                throw AIError.providerNotConfigured("anthropic")
            }
            return AnthropicProvider(apiKey: key, model: model)
        case "gemini":
            guard case .apiKey(let key) = configs["gemini"] else {
                throw AIError.providerNotConfigured("gemini")
            }
            return GeminiProvider(apiKey: key, model: model)
        case "groq":
            guard case .apiKey(let key) = configs["groq"] else {
                throw AIError.providerNotConfigured("groq")
            }
            return OpenAICompatibleProvider(baseURL: "https://api.groq.com/openai/v1", apiKey: key, model: model)
        case "openrouter":
            guard case .apiKey(let key) = configs["openrouter"] else {
                throw AIError.providerNotConfigured("openrouter")
            }
            return OpenAICompatibleProvider(baseURL: "https://openrouter.ai/api/v1", apiKey: key, model: model)
        case "mistral":
            guard case .apiKey(let key) = configs["mistral"] else {
                throw AIError.providerNotConfigured("mistral")
            }
            return OpenAICompatibleProvider(baseURL: "https://api.mistral.ai/v1", apiKey: key, model: model)
        case "cohere":
            guard case .apiKey(let key) = configs["cohere"] else {
                throw AIError.providerNotConfigured("cohere")
            }
            return OpenAICompatibleProvider(baseURL: "https://api.cohere.com/compatibility/v1", apiKey: key, model: model)
        case "cloudflare":
            guard case .cloudflare(let accountID, let key) = configs["cloudflare"] else {
                throw AIError.providerNotConfigured("cloudflare")
            }
            return OpenAICompatibleProvider(
                baseURL: "https://api.cloudflare.com/client/v4/accounts/\(accountID)/ai/v1",
                apiKey: key,
                model: model
            )
        case "ollama":
            let baseURL: String
            if case .ollama(let url) = configs["ollama"] { baseURL = url }
            else { baseURL = "http://localhost:11434/v1" }
            return OpenAICompatibleProvider(baseURL: baseURL, apiKey: "", model: model)
        default:
            throw AIError.providerNotConfigured(provider)
        }
    }

    func resolveImageModel(_ modelString: String) throws -> any AIImageModel {
        let resolved = try resolveMediaProvider(modelString)
        guard let model = resolved as? any AIImageModel else {
            throw AIError.unsupportedFeature("Image generation is not supported by \(modelString)")
        }
        return model
    }

    func resolveTranscriptionModel(_ modelString: String) throws -> any AITranscriptionModel {
        let resolved = try resolveMediaProvider(modelString)
        guard let model = resolved as? any AITranscriptionModel else {
            throw AIError.unsupportedFeature("Transcription is not supported by \(modelString)")
        }
        return model
    }

    func resolveSpeechModel(_ modelString: String) throws -> any AISpeechModel {
        let resolved = try resolveMediaProvider(modelString)
        guard let model = resolved as? any AISpeechModel else {
            throw AIError.unsupportedFeature("Speech generation is not supported by \(modelString)")
        }
        return model
    }

    func resolveVideoModel(_ modelString: String) throws -> any AIVideoModel {
        let resolved = try resolveMediaProvider(modelString)
        guard let model = resolved as? any AIVideoModel else {
            throw AIError.unsupportedFeature("Video generation is not supported by \(modelString)")
        }
        return model
    }

    private func resolveMediaProvider(_ modelString: String) throws -> Any {
        let parts = modelString.split(separator: "/", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { throw AIError.invalidModelString(modelString) }
        let provider = parts[0].lowercased()
        let model = parts[1]

        switch provider {
        case "openai":
            guard case .apiKey(let key) = configs["openai"] else {
                throw AIError.providerNotConfigured("openai")
            }
            return OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: key, model: model)
        case "gemini":
            guard case .apiKey(let key) = configs["gemini"] else {
                throw AIError.providerNotConfigured("gemini")
            }
            return GeminiProvider(apiKey: key, model: model)
        default:
            throw AIError.unsupportedFeature("Media generation is not supported for provider '\(provider)'")
        }
    }
}
