public typealias LanguageModelNext = @Sendable (LanguageModelRequest) async throws -> AIResponse
public typealias LanguageModelStreamNext = @Sendable (LanguageModelStreamRequest) -> AsyncThrowingStream<AIStreamChunk, Error>

public struct LanguageModelContinuation: Sendable {
    private let handler: LanguageModelNext

    init(_ handler: @escaping LanguageModelNext) {
        self.handler = handler
    }

    public func generate(_ request: LanguageModelRequest) async throws -> AIResponse {
        try await handler(request)
    }

    public func generate(prompt: String, options: GenerationOptions = GenerationOptions()) async throws -> AIResponse {
        try await handler(LanguageModelRequest(prompt: prompt, options: options))
    }

    public func generate(prompt: [AIMessageContent], options: GenerationOptions = GenerationOptions()) async throws -> AIResponse {
        try await handler(LanguageModelRequest(prompt: prompt, options: options))
    }

    public func callAsFunction(_ request: LanguageModelRequest) async throws -> AIResponse {
        try await handler(request)
    }
}

public struct LanguageModelStreamContinuation: Sendable {
    private let streamHandler: LanguageModelStreamNext
    private let generateHandler: LanguageModelNext?

    init(
        stream: @escaping LanguageModelStreamNext,
        generate: LanguageModelNext?
    ) {
        self.streamHandler = stream
        self.generateHandler = generate
    }

    public func stream(_ request: LanguageModelStreamRequest) -> AsyncThrowingStream<AIStreamChunk, Error> {
        streamHandler(request)
    }

    public func generate(_ request: LanguageModelRequest) async throws -> AIResponse {
        guard let generateHandler else {
            throw AIError.unsupportedFeature("Streaming middleware cannot access a generation fallback for this model")
        }
        return try await generateHandler(request)
    }

    public func generate(_ request: LanguageModelStreamRequest) async throws -> AIResponse {
        try await generate(request.languageRequest)
    }

    public func callAsFunction(_ request: LanguageModelStreamRequest) -> AsyncThrowingStream<AIStreamChunk, Error> {
        streamHandler(request)
    }
}

public struct LanguageModelMiddleware: Sendable {
    public let run: @Sendable (LanguageModelRequest, LanguageModelContinuation) async throws -> AIResponse

    public init(
        _ run: @escaping @Sendable (LanguageModelRequest, LanguageModelContinuation) async throws -> AIResponse
    ) {
        self.run = run
    }
}

public struct LanguageModelStreamMiddleware: Sendable {
    public let run: @Sendable (LanguageModelStreamRequest, LanguageModelStreamContinuation) -> AsyncThrowingStream<AIStreamChunk, Error>

    public init(
        _ run: @escaping @Sendable (LanguageModelStreamRequest, LanguageModelStreamContinuation) -> AsyncThrowingStream<AIStreamChunk, Error>
    ) {
        self.run = run
    }
}
