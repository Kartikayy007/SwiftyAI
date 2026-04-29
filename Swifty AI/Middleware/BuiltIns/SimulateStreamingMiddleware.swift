public func simulateStreamingMiddleware(
    chunkSize: Int = 24,
    delay: Duration = .zero
) -> LanguageModelStreamMiddleware {
    LanguageModelStreamMiddleware { request, next in
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let response = try await next.generate(request)
                    let chunks = TextChunker.chunks(response.text, maxLength: chunkSize)

                    if chunks.isEmpty {
                        continuation.yield(
                            AIStreamChunk(text: "", finishReason: response.finishReason, usage: response.usage)
                        )
                        continuation.finish()
                        return
                    }

                    for index in chunks.indices {
                        if Task.isCancelled {
                            continuation.finish()
                            return
                        }
                        if delay != .zero {
                            try await Task.sleep(for: delay)
                        }
                        let isLast = index == chunks.index(before: chunks.endIndex)
                        continuation.yield(
                            AIStreamChunk(
                                text: chunks[index],
                                finishReason: isLast ? response.finishReason : nil,
                                usage: isLast ? response.usage : nil
                            )
                        )
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
