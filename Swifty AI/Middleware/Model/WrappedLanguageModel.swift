public struct WrappedLanguageModel: AIModel {
    private let handler: LanguageModelNext

    init(_ handler: @escaping LanguageModelNext) {
        self.handler = handler
    }

    public func generate(_ prompt: String) async throws -> AIResponse {
        try await generate(prompt, options: GenerationOptions())
    }

    public func generate(_ prompt: String, options: GenerationOptions) async throws -> AIResponse {
        try await handler(LanguageModelRequest(prompt: prompt, options: options))
    }

    public func generate(_ prompt: [AIMessageContent], options: GenerationOptions) async throws -> AIResponse {
        try await handler(LanguageModelRequest(prompt: prompt, options: options))
    }
}

public struct WrappedStreamingLanguageModel: AIStreamModel {
    private let generateHandler: LanguageModelNext
    private let streamHandler: LanguageModelStreamNext

    init(
        generate: @escaping LanguageModelNext,
        stream: @escaping LanguageModelStreamNext
    ) {
        self.generateHandler = generate
        self.streamHandler = stream
    }

    public func generate(_ prompt: String) async throws -> AIResponse {
        try await generate(prompt, options: GenerationOptions())
    }

    public func generate(_ prompt: String, options: GenerationOptions) async throws -> AIResponse {
        try await generateHandler(LanguageModelRequest(prompt: prompt, options: options))
    }

    public func generate(_ prompt: [AIMessageContent], options: GenerationOptions) async throws -> AIResponse {
        try await generateHandler(LanguageModelRequest(prompt: prompt, options: options))
    }

    public func stream(_ prompt: String) -> AsyncThrowingStream<AIStreamChunk, Error> {
        stream(prompt, options: GenerationOptions())
    }

    public func stream(_ prompt: String, options: GenerationOptions) -> AsyncThrowingStream<AIStreamChunk, Error> {
        streamHandler(LanguageModelStreamRequest(prompt: prompt, options: options))
    }

    public func stream(_ prompt: [AIMessageContent], options: GenerationOptions) -> AsyncThrowingStream<AIStreamChunk, Error> {
        streamHandler(LanguageModelStreamRequest(prompt: prompt, options: options))
    }

    public func stream(messages: [ChatMessage]) -> AsyncThrowingStream<AIStreamChunk, Error> {
        stream(messages: messages, options: GenerationOptions())
    }

    public func stream(messages: [ChatMessage], options: GenerationOptions) -> AsyncThrowingStream<AIStreamChunk, Error> {
        streamHandler(LanguageModelStreamRequest(messages: messages, options: options))
    }
}

public func wrapLanguageModel(
    _ model: any AIModel,
    middleware: [LanguageModelMiddleware]
) -> any AIModel {
    WrappedLanguageModel(makeLanguageModelChain(model: model, middleware: middleware))
}

public func wrapLanguageModel(
    _ model: any AIModel,
    middleware: [LanguageModelMiddleware] = [],
    streamMiddleware: [LanguageModelStreamMiddleware]
) -> any AIStreamModel {
    WrappedStreamingLanguageModel(
        generate: makeLanguageModelChain(model: model, middleware: middleware),
        stream: makeLanguageModelStreamChain(
            model: model,
            streamingModel: nil,
            middleware: middleware,
            streamMiddleware: streamMiddleware
        )
    )
}

public func wrapStreamingLanguageModel(
    _ model: any AIStreamModel,
    middleware: [LanguageModelMiddleware] = [],
    streamMiddleware: [LanguageModelStreamMiddleware] = []
) -> any AIStreamModel {
    WrappedStreamingLanguageModel(
        generate: makeLanguageModelChain(model: model, middleware: middleware),
        stream: makeLanguageModelStreamChain(
            model: model,
            streamingModel: model,
            middleware: middleware,
            streamMiddleware: streamMiddleware
        )
    )
}

private func makeLanguageModelChain(
    model: any AIModel,
    middleware: [LanguageModelMiddleware]
) -> LanguageModelNext {
    let base: LanguageModelNext = { request in
        try await model.generate(request.prompt, options: request.options)
    }
    return middleware.reversed().reduce(base) { next, middleware in
        { request in
            try await middleware.run(request, LanguageModelContinuation(next))
        }
    }
}

private func makeLanguageModelStreamChain(
    model: any AIModel,
    streamingModel: (any AIStreamModel)?,
    middleware: [LanguageModelMiddleware],
    streamMiddleware: [LanguageModelStreamMiddleware]
) -> LanguageModelStreamNext {
    let generate = makeLanguageModelChain(model: model, middleware: middleware)
    let base: LanguageModelStreamNext = { request in
        guard let streamingModel else {
            return failingLanguageModelStream(
                AIError.unsupportedFeature("Streaming is not supported by this model. Add simulateStreamingMiddleware() to stream generated text.")
            )
        }
        if let messages = request.messages {
            return streamingModel.stream(messages: messages, options: request.options)
        }
        return streamingModel.stream(request.prompt ?? [.text("")], options: request.options)
    }
    return streamMiddleware.reversed().reduce(base) { next, middleware in
        { request in
            middleware.run(
                request,
                LanguageModelStreamContinuation(stream: next, generate: generate)
            )
        }
    }
}

func failingLanguageModelStream(_ error: Error) -> AsyncThrowingStream<AIStreamChunk, Error> {
    AsyncThrowingStream { continuation in
        continuation.finish(throwing: error)
    }
}
