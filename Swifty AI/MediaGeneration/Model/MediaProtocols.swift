import Foundation

public protocol AIImageModel: Sendable {
    func generateImage(prompt: String, options: ImageGenerationOptions) async throws -> ImageResponse
}

public protocol AITranscriptionModel: Sendable {
    func transcribe(_ audio: AIAudioInput, options: TranscriptionOptions) async throws -> TranscriptionResponse
}

public protocol AISpeechModel: Sendable {
    func generateSpeech(_ text: String, options: SpeechOptions) async throws -> SpeechResponse
}

public protocol AIVideoModel: Sendable {
    func generateVideo(prompt: String, options: VideoGenerationOptions) async throws -> VideoResponse
}

typealias ImageModelNext = @Sendable (String, ImageGenerationOptions) async throws -> ImageResponse

public struct ImageGenerationRequest: Sendable {
    public var prompt: String
    public var options: ImageGenerationOptions

    public init(prompt: String, options: ImageGenerationOptions) {
        self.prompt = prompt
        self.options = options
    }
}

public struct ImageModelContinuation: Sendable {
    private let handler: ImageModelNext

    init(_ handler: @escaping ImageModelNext) {
        self.handler = handler
    }

    public func generate(prompt: String, options: ImageGenerationOptions) async throws -> ImageResponse {
        try await handler(prompt, options)
    }

    public func callAsFunction(_ request: ImageGenerationRequest) async throws -> ImageResponse {
        try await handler(request.prompt, request.options)
    }
}

public struct ImageModelMiddleware: Sendable {
    public let run: @Sendable (ImageGenerationRequest, ImageModelContinuation) async throws -> ImageResponse

    public init(
        _ run: @escaping @Sendable (ImageGenerationRequest, ImageModelContinuation) async throws -> ImageResponse
    ) {
        self.run = run
    }
}

public struct WrappedImageModel: AIImageModel {
    private let handler: ImageModelNext

    init(_ handler: @escaping ImageModelNext) {
        self.handler = handler
    }

    public func generateImage(prompt: String, options: ImageGenerationOptions) async throws -> ImageResponse {
        try await handler(prompt, options)
    }
}

public func wrapImageModel(
    _ model: any AIImageModel,
    middleware: [ImageModelMiddleware]
) -> any AIImageModel {
    let base: ImageModelNext = { prompt, options in
        try await model.generateImage(prompt: prompt, options: options)
    }
    let chain = middleware.reversed().reduce(base) { next, middleware in
        { prompt, options in
            let request = ImageGenerationRequest(prompt: prompt, options: options)
            return try await middleware.run(request, ImageModelContinuation(next))
        }
    }
    return WrappedImageModel(chain)
}
