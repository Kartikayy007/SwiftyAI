public func streamText(
    model: some AIStreamModel,
    prompt: String,
    options: GenerationOptions = GenerationOptions(),
    onChunk: ((AIStreamChunk) -> Void)? = nil,
    onFinish: ((AIResponse) -> Void)? = nil
) -> AsyncThrowingStream<AIStreamChunk, Error> {
    guard onChunk != nil || onFinish != nil else {
        return model.stream(prompt, options: options)
    }
    return AsyncThrowingStream { continuation in
        Task {
            var fullText = ""
            var lastUsage: TokenUsage?
            var lastFinishReason: String?
            do {
                for try await chunk in model.stream(prompt, options: options) {
                    onChunk?(chunk)
                    fullText += chunk.text
                    if let u = chunk.usage { lastUsage = u }
                    if let r = chunk.finishReason { lastFinishReason = r }
                    continuation.yield(chunk)
                }
                onFinish?(AIResponse(text: fullText, model: nil, usage: lastUsage, finishReason: lastFinishReason))
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}

public func streamText(
    model: String,
    prompt: String,
    options: GenerationOptions = GenerationOptions(),
    onChunk: ((AIStreamChunk) -> Void)? = nil,
    onFinish: ((AIResponse) -> Void)? = nil
) -> AsyncThrowingStream<AIStreamChunk, Error> {
    AsyncThrowingStream { continuation in
        Task {
            do {
                let resolved = try await AIRegistry.shared.resolve(model)
                for try await chunk in streamText(model: resolved, prompt: prompt, options: options, onChunk: onChunk, onFinish: onFinish) {
                    continuation.yield(chunk)
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}
