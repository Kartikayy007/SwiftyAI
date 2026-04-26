public func streamText(model: some AIStreamModel, prompt: String) -> AsyncThrowingStream<AIStreamChunk, Error> {
    model.stream(prompt)
}
