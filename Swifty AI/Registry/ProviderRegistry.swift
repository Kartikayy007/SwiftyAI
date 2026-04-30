/// A public registry for resolving custom provider model strings.
///
/// `ProviderRegistry` is independent from `AI.configure` and the internal shared
/// registry. Use it when you want explicit, app- or test-local model resolution.
public struct ProviderRegistry: Sendable {
    /// A group of models exposed under one provider id.
    public struct Provider: Sendable {
        fileprivate let languageModels: [String: any AIModel]
        fileprivate let streamModels: [String: any AIStreamModel]
        fileprivate let toolCallingModels: [String: any AIToolCallingModel]
        fileprivate let imageModels: [String: any AIImageModel]
        fileprivate let transcriptionModels: [String: any AITranscriptionModel]
        fileprivate let speechModels: [String: any AISpeechModel]
        fileprivate let videoModels: [String: any AIVideoModel]
        fileprivate let embeddingModels: [String: any AIEmbeddingModel]
        fileprivate let rerankModels: [String: any AIRerankModel]

        /// Creates a custom provider from modality-specific model maps.
        public init(
            languageModels: [String: any AIModel] = [:],
            streamModels: [String: any AIStreamModel] = [:],
            toolCallingModels: [String: any AIToolCallingModel] = [:],
            imageModels: [String: any AIImageModel] = [:],
            transcriptionModels: [String: any AITranscriptionModel] = [:],
            speechModels: [String: any AISpeechModel] = [:],
            videoModels: [String: any AIVideoModel] = [:],
            embeddingModels: [String: any AIEmbeddingModel] = [:],
            rerankModels: [String: any AIRerankModel] = [:]
        ) {
            self.languageModels = languageModels
            self.streamModels = streamModels
            self.toolCallingModels = toolCallingModels
            self.imageModels = imageModels
            self.transcriptionModels = transcriptionModels
            self.speechModels = speechModels
            self.videoModels = videoModels
            self.embeddingModels = embeddingModels
            self.rerankModels = rerankModels
        }
    }

    private struct ModelID {
        let provider: String
        let model: String
    }

    private let providers: [String: Provider]

    /// Creates a registry from provider ids to custom providers.
    public init(_ providers: [String: Provider]) {
        self.providers = providers
    }

    /// Resolves an `AIModel` string such as `"mock/chat"`.
    public func model(_ modelString: String) throws -> any AIModel {
        try resolve(modelString, modality: "language model") { provider, model in
            if let languageModel = provider.languageModels[model] {
                return languageModel
            }
            if let streamModel = provider.streamModels[model] {
                return streamModel
            }
            if let toolCallingModel = provider.toolCallingModels[model] {
                return toolCallingModel
            }
            return nil
        }
    }

    /// Resolves an `AIModel` string such as `"mock/chat"`.
    public func languageModel(_ modelString: String) throws -> any AIModel {
        try model(modelString)
    }

    /// Resolves an `AIStreamModel` string such as `"mock/chat"`.
    public func streamModel(_ modelString: String) throws -> any AIStreamModel {
        try resolve(modelString, modality: "stream model") { provider, model in
            if let streamModel = provider.streamModels[model] {
                return streamModel
            }
            if let toolCallingModel = provider.toolCallingModels[model] {
                return toolCallingModel
            }
            return nil
        }
    }

    /// Resolves an `AIToolCallingModel` string such as `"mock/chat"`.
    public func toolCallingModel(_ modelString: String) throws -> any AIToolCallingModel {
        try resolve(modelString, modality: "tool calling model") { provider, model in
            provider.toolCallingModels[model]
        }
    }

    /// Resolves an `AIImageModel` string such as `"mock/image"`.
    public func imageModel(_ modelString: String) throws -> any AIImageModel {
        try resolve(modelString, modality: "image model") { provider, model in
            provider.imageModels[model]
        }
    }

    /// Resolves an `AITranscriptionModel` string such as `"mock/transcribe"`.
    public func transcriptionModel(_ modelString: String) throws -> any AITranscriptionModel {
        try resolve(modelString, modality: "transcription model") { provider, model in
            provider.transcriptionModels[model]
        }
    }

    /// Resolves an `AISpeechModel` string such as `"mock/speech"`.
    public func speechModel(_ modelString: String) throws -> any AISpeechModel {
        try resolve(modelString, modality: "speech model") { provider, model in
            provider.speechModels[model]
        }
    }

    /// Resolves an `AIVideoModel` string such as `"mock/video"`.
    public func videoModel(_ modelString: String) throws -> any AIVideoModel {
        try resolve(modelString, modality: "video model") { provider, model in
            provider.videoModels[model]
        }
    }

    /// Resolves an `AIEmbeddingModel` string such as `"mock/embed"`.
    public func embeddingModel(_ modelString: String) throws -> any AIEmbeddingModel {
        try resolve(modelString, modality: "embedding model") { provider, model in
            provider.embeddingModels[model]
        }
    }

    /// Resolves an `AIRerankModel` string such as `"mock/rerank"`.
    public func rerankModel(_ modelString: String) throws -> any AIRerankModel {
        try resolve(modelString, modality: "rerank model") { provider, model in
            provider.rerankModels[model]
        }
    }

    private func resolve<Model>(
        _ modelString: String,
        modality: String,
        lookup: (Provider, String) -> Model?
    ) throws -> Model {
        let id = try parse(modelString)
        guard let provider = providers[id.provider] else {
            throw AIError.providerNotConfigured(id.provider)
        }
        guard let model = lookup(provider, id.model) else {
            throw AIError.unsupportedFeature(
                "No \(modality) '\(id.model)' is registered for provider '\(id.provider)'"
            )
        }
        return model
    }

    private func parse(_ modelString: String) throws -> ModelID {
        let parts = modelString.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty, !parts[1].isEmpty else {
            throw AIError.invalidModelString(modelString)
        }
        return ModelID(provider: String(parts[0]), model: String(parts[1]))
    }
}

/// Creates a public provider registry from provider ids to providers.
public func createProviderRegistry(_ providers: [String: ProviderRegistry.Provider]) -> ProviderRegistry {
    ProviderRegistry(providers)
}

/// Creates a custom provider from modality-specific model maps.
public func customProvider(
    languageModels: [String: any AIModel] = [:],
    streamModels: [String: any AIStreamModel] = [:],
    toolCallingModels: [String: any AIToolCallingModel] = [:],
    imageModels: [String: any AIImageModel] = [:],
    transcriptionModels: [String: any AITranscriptionModel] = [:],
    speechModels: [String: any AISpeechModel] = [:],
    videoModels: [String: any AIVideoModel] = [:],
    embeddingModels: [String: any AIEmbeddingModel] = [:],
    rerankModels: [String: any AIRerankModel] = [:]
) -> ProviderRegistry.Provider {
    ProviderRegistry.Provider(
        languageModels: languageModels,
        streamModels: streamModels,
        toolCallingModels: toolCallingModels,
        imageModels: imageModels,
        transcriptionModels: transcriptionModels,
        speechModels: speechModels,
        videoModels: videoModels,
        embeddingModels: embeddingModels,
        rerankModels: rerankModels
    )
}

public func generateText(
    model: String,
    registry: ProviderRegistry,
    prompt: String,
    options: GenerationOptions = GenerationOptions()
) async throws -> AIResponse {
    let resolved = try registry.model(model)
    return try await generateText(model: resolved, prompt: prompt, options: options)
}

public func generateText(
    model: String,
    registry: ProviderRegistry,
    prompt: [AIMessageContent],
    options: GenerationOptions = GenerationOptions()
) async throws -> AIResponse {
    let resolved = try registry.model(model)
    return try await generateText(model: resolved, prompt: prompt, options: options)
}

public func streamText(
    model: String,
    registry: ProviderRegistry,
    prompt: String,
    options: GenerationOptions = GenerationOptions(),
    onChunk: ((AIStreamChunk) -> Void)? = nil,
    onFinish: ((AIResponse) -> Void)? = nil
) -> AsyncThrowingStream<AIStreamChunk, Error> {
    AsyncThrowingStream { continuation in
        Task {
            do {
                let resolved = try registry.streamModel(model)
                for try await chunk in streamText(
                    model: resolved,
                    prompt: prompt,
                    options: options,
                    onChunk: onChunk,
                    onFinish: onFinish
                ) {
                    continuation.yield(chunk)
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}

public func streamText(
    model: String,
    registry: ProviderRegistry,
    prompt: [AIMessageContent],
    options: GenerationOptions = GenerationOptions(),
    onChunk: ((AIStreamChunk) -> Void)? = nil,
    onFinish: ((AIResponse) -> Void)? = nil
) -> AsyncThrowingStream<AIStreamChunk, Error> {
    AsyncThrowingStream { continuation in
        Task {
            do {
                let resolved = try registry.streamModel(model)
                for try await chunk in streamText(
                    model: resolved,
                    prompt: prompt,
                    options: options,
                    onChunk: onChunk,
                    onFinish: onFinish
                ) {
                    continuation.yield(chunk)
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}

public func generateWithTools(
    model: String,
    registry: ProviderRegistry,
    prompt: String,
    tools: [AITool],
    options: GenerationOptions = GenerationOptions(),
    maxSteps: Int = 5,
    stopWhen: [AIStopCondition] = [isLoopFinished()],
    onStepFinish: ((AIStep) -> Void)? = nil,
    toolOptions: ToolExecutionOptions = .default
) async throws -> AIStepResult {
    let resolved = try registry.toolCallingModel(model)
    return try await generateWithTools(
        model: resolved,
        prompt: prompt,
        tools: tools,
        options: options,
        maxSteps: maxSteps,
        stopWhen: stopWhen,
        onStepFinish: onStepFinish,
        toolOptions: toolOptions
    )
}

public func streamWithTools(
    model: String,
    registry: ProviderRegistry,
    prompt: String,
    tools: [AITool],
    options: GenerationOptions = GenerationOptions(),
    maxSteps: Int = 5,
    stopWhen: [AIStopCondition] = [isLoopFinished()],
    onChunk: ((AIAgentChunk) -> Void)? = nil,
    onStepFinish: ((AIStep) -> Void)? = nil,
    onFinish: ((AIStepResult) -> Void)? = nil,
    toolOptions: ToolExecutionOptions = .default
) -> AsyncThrowingStream<AIAgentChunk, Error> {
    AsyncThrowingStream { continuation in
        Task {
            do {
                let resolved = try registry.toolCallingModel(model)
                for try await chunk in streamWithTools(
                    model: resolved,
                    prompt: prompt,
                    tools: tools,
                    options: options,
                    maxSteps: maxSteps,
                    stopWhen: stopWhen,
                    onChunk: onChunk,
                    onStepFinish: onStepFinish,
                    onFinish: onFinish,
                    toolOptions: toolOptions
                ) {
                    continuation.yield(chunk)
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}

public func generateImage(
    model: String,
    registry: ProviderRegistry,
    prompt: String,
    options: ImageGenerationOptions = ImageGenerationOptions()
) async throws -> ImageResponse {
    let resolved = try registry.imageModel(model)
    return try await generateImage(model: resolved, prompt: prompt, options: options)
}

public func transcribe(
    model: String,
    registry: ProviderRegistry,
    audio: AIAudioInput,
    options: TranscriptionOptions = TranscriptionOptions()
) async throws -> TranscriptionResponse {
    let resolved = try registry.transcriptionModel(model)
    return try await transcribe(model: resolved, audio: audio, options: options)
}

public func generateSpeech(
    model: String,
    registry: ProviderRegistry,
    text: String,
    options: SpeechOptions = SpeechOptions()
) async throws -> SpeechResponse {
    let resolved = try registry.speechModel(model)
    return try await generateSpeech(model: resolved, text: text, options: options)
}

public func generateVideo(
    model: String,
    registry: ProviderRegistry,
    prompt: String,
    options: VideoGenerationOptions = VideoGenerationOptions()
) async throws -> VideoResponse {
    let resolved = try registry.videoModel(model)
    return try await generateVideo(model: resolved, prompt: prompt, options: options)
}

public func embed(
    model: String,
    registry: ProviderRegistry,
    input: String,
    options: EmbeddingOptions = EmbeddingOptions()
) async throws -> EmbeddingResponse {
    let resolved = try registry.embeddingModel(model)
    return try await embed(model: resolved, input: input, options: options)
}

public func embedMany(
    model: String,
    registry: ProviderRegistry,
    inputs: [String],
    options: EmbeddingOptions = EmbeddingOptions()
) async throws -> EmbeddingResponse {
    let resolved = try registry.embeddingModel(model)
    return try await embedMany(model: resolved, inputs: inputs, options: options)
}

public func rerank(
    model: String,
    registry: ProviderRegistry,
    query: String,
    documents: [RerankDocument],
    options: RerankOptions = RerankOptions()
) async throws -> RerankResponse {
    let resolved = try registry.rerankModel(model)
    return try await rerank(model: resolved, query: query, documents: documents, options: options)
}

public func rerank(
    model: String,
    registry: ProviderRegistry,
    query: String,
    documents: [String],
    options: RerankOptions = RerankOptions()
) async throws -> RerankResponse {
    let resolved = try registry.rerankModel(model)
    return try await rerank(model: resolved, query: query, documents: documents, options: options)
}
