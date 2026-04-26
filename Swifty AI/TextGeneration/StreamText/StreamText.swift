public func streamText(model: some AIStreamModel, prompt: String) -> AsyncThrowingStream<AIStreamChunk, Error> {
    model.stream(prompt)
}

public func streamText(model: String, prompt: String) -> AsyncThrowingStream<AIStreamChunk, Error> {
    AsyncThrowingStream { continuation in
        Task {
            do {
                let resolved = try await AIRegistry.shared.resolve(model)
                for try await chunk in streamText(model: resolved, prompt: prompt) {
                    continuation.yield(chunk)
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}
