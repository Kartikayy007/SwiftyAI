import Foundation
import os

final class AIRegistry: @unchecked Sendable {
    static let shared = AIRegistry()

    enum ProviderConfig {
        case apiKey(String)
        case cloudflare(accountID: String, apiKey: String)
        case ollama(baseURL: String)
        #if canImport(FoundationModels)
        case appleFoundation
        #endif
    }

    private let storage = OSAllocatedUnfairLock<[String: ProviderConfig]>(initialState: [:])

    init() {}

    func set(_ config: ProviderConfig, for provider: String) {
        storage.withLock { $0[provider] = config }
    }

    private func config(for provider: String) -> ProviderConfig? {
        storage.withLock { $0[provider] }
    }

    func resolve(_ modelString: String) async throws -> any AIStreamModel {
        let parts = modelString.split(separator: "/", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { throw AIError.invalidModelString(modelString) }
        let provider = parts[0].lowercased()
        let model = parts[1]

        switch provider {
        case "openai":
            guard case .apiKey(let key) = config(for: "openai") else {
                throw AIError.providerNotConfigured("openai")
            }
            return OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: key, model: model)
        case "anthropic":
            guard case .apiKey(let key) = config(for: "anthropic") else {
                throw AIError.providerNotConfigured("anthropic")
            }
            return AnthropicProvider(apiKey: key, model: model)
        case "gemini":
            guard case .apiKey(let key) = config(for: "gemini") else {
                throw AIError.providerNotConfigured("gemini")
            }
            return GeminiProvider(apiKey: key, model: model)
        case "groq":
            guard case .apiKey(let key) = config(for: "groq") else {
                throw AIError.providerNotConfigured("groq")
            }
            return OpenAICompatibleProvider(baseURL: "https://api.groq.com/openai/v1", apiKey: key, model: model)
        case "openrouter":
            guard case .apiKey(let key) = config(for: "openrouter") else {
                throw AIError.providerNotConfigured("openrouter")
            }
            return OpenAICompatibleProvider(baseURL: "https://openrouter.ai/api/v1", apiKey: key, model: model)
        case "mistral":
            guard case .apiKey(let key) = config(for: "mistral") else {
                throw AIError.providerNotConfigured("mistral")
            }
            return OpenAICompatibleProvider(baseURL: "https://api.mistral.ai/v1", apiKey: key, model: model)
        case "cohere":
            guard case .apiKey(let key) = config(for: "cohere") else {
                throw AIError.providerNotConfigured("cohere")
            }
            return OpenAICompatibleProvider(baseURL: "https://api.cohere.com/compatibility/v1", apiKey: key, model: model)
        case "cloudflare":
            guard case .cloudflare(let accountID, let key) = config(for: "cloudflare") else {
                throw AIError.providerNotConfigured("cloudflare")
            }
            return OpenAICompatibleProvider(
                baseURL: "https://api.cloudflare.com/client/v4/accounts/\(accountID)/ai/v1",
                apiKey: key,
                model: model
            )
        case "ollama":
            let baseURL: String
            if case .ollama(let url) = config(for: "ollama") { baseURL = url }
            else { baseURL = "http://localhost:11434/v1" }
            return OpenAICompatibleProvider(baseURL: baseURL, apiKey: "", model: model)
        case "applefoundation":
            #if canImport(FoundationModels)
            guard case .appleFoundation = config(for: "applefoundation") else {
                throw AIError.providerNotConfigured("applefoundation")
            }
            if #available(iOS 26, macOS 26, *) {
                return AppleFoundationProvider()
            } else {
                throw AIError.unsupportedFeature("Apple Foundation requires iOS 26 or macOS 26")
            }
            #else
            throw AIError.unsupportedFeature("Apple Foundation is not available on this platform")
            #endif
        default:
            throw AIError.providerNotConfigured(provider)
        }
    }

    func resolveImageModel(_ modelString: String) async throws -> any AIImageModel {
        let resolved = try resolveMediaProvider(modelString)
        guard let model = resolved as? any AIImageModel else {
            throw AIError.unsupportedFeature("Image generation is not supported by \(modelString)")
        }
        return model
    }

    func resolveTranscriptionModel(_ modelString: String) async throws -> any AITranscriptionModel {
        let resolved = try resolveMediaProvider(modelString)
        guard let model = resolved as? any AITranscriptionModel else {
            throw AIError.unsupportedFeature("Transcription is not supported by \(modelString)")
        }
        return model
    }

    func resolveSpeechModel(_ modelString: String) async throws -> any AISpeechModel {
        let resolved = try resolveMediaProvider(modelString)
        guard let model = resolved as? any AISpeechModel else {
            throw AIError.unsupportedFeature("Speech generation is not supported by \(modelString)")
        }
        return model
    }

    func resolveVideoModel(_ modelString: String) async throws -> any AIVideoModel {
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
            guard case .apiKey(let key) = config(for: "openai") else {
                throw AIError.providerNotConfigured("openai")
            }
            return OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: key, model: model)
        case "gemini":
            guard case .apiKey(let key) = config(for: "gemini") else {
                throw AIError.providerNotConfigured("gemini")
            }
            return GeminiProvider(apiKey: key, model: model)
        default:
            throw AIError.unsupportedFeature("Media generation is not supported for provider '\(provider)'")
        }
    }
}
