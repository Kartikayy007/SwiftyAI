import Foundation

public func simulateReadableStream(
    _ text: String,
    chunkSize: Int,
    delay: Duration? = nil
) -> AsyncThrowingStream<String, Error> {
    simulateReadableStream(splitIntoChunks(text, chunkSize: chunkSize), delay: delay)
}

public func simulateReadableStream(
    _ chunks: [String],
    delay: Duration? = nil
) -> AsyncThrowingStream<String, Error> {
    AsyncThrowingStream { continuation in
        let task = Task {
            for chunk in chunks {
                if Task.isCancelled { break }

                if let delay = delay {
                    do {
                        try await Task.sleep(for: delay)
                    } catch {
                        break
                    }
                }

                if Task.isCancelled { break }
                continuation.yield(chunk)
            }

            continuation.finish()
        }

        continuation.onTermination = { @Sendable _ in
            task.cancel()
        }
    }
}

public func smoothStream<S: AsyncSequence>(
    _ stream: S,
    charactersPerChunk: Int,
    interval: Duration
) -> AsyncThrowingStream<String, Error> where S.Element == String {
    let chunkSize = max(1, charactersPerChunk)

    return AsyncThrowingStream { continuation in
        let task = Task {
            var buffer = ""

            do {
                for try await chunk in stream {
                    if Task.isCancelled { break }

                    buffer += chunk

                    while buffer.count >= chunkSize {
                        if Task.isCancelled { break }

                        continuation.yield(takePrefix(from: &buffer, count: chunkSize))

                        do {
                            try await Task.sleep(for: interval)
                        } catch {
                            break
                        }
                    }
                }

                if !Task.isCancelled, !buffer.isEmpty {
                    continuation.yield(buffer)
                }

                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }

        continuation.onTermination = { @Sendable _ in
            task.cancel()
        }
    }
}

private func splitIntoChunks(_ text: String, chunkSize: Int) -> [String] {
    guard !text.isEmpty else { return [] }
    guard chunkSize > 0 else { return [text] }

    var chunks: [String] = []
    var start = text.startIndex

    while start < text.endIndex {
        let end = text.index(start, offsetBy: chunkSize, limitedBy: text.endIndex) ?? text.endIndex
        chunks.append(String(text[start..<end]))
        start = end
    }

    return chunks
}

private func takePrefix(from buffer: inout String, count: Int) -> String {
    let end = buffer.index(buffer.startIndex, offsetBy: count, limitedBy: buffer.endIndex) ?? buffer.endIndex
    let chunk = String(buffer[..<end])
    buffer.removeSubrange(buffer.startIndex..<end)
    return chunk
}
