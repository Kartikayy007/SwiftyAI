import Foundation

func sseLines(
    request: URLRequest,
    session: URLSession = .shared,
    options: GenerationOptions = GenerationOptions()
) -> AsyncThrowingStream<String, Error> {
    AsyncThrowingStream { continuation in
        Task {
            do {
                var request = request
                for (key, value) in options.headers {
                    request.setValue(value, forHTTPHeaderField: key)
                }

                let (bytes, response) = try await session.bytes(for: request)

                guard let http = response as? HTTPURLResponse else {
                    continuation.finish(throwing: AIError.invalidResponse)
                    return
                }

                guard (200..<300).contains(http.statusCode) else {
                    continuation.finish(throwing: AIError.apiError(statusCode: http.statusCode, message: "HTTP \(http.statusCode)"))
                    return
                }

                for try await line in bytes.lines {
                    if Task.isCancelled {
                        continuation.finish()
                        return
                    }

                    if line.hasPrefix(":") { continue }
                    if line.isEmpty { continue }
                    guard line.hasPrefix("data: ") else { continue }

                    let payload = String(line.dropFirst(6))
                    if payload == "[DONE]" {
                        continuation.finish()
                        return
                    }

                    continuation.yield(payload)
                }

                continuation.finish()
            } catch let error as AIError {
                continuation.finish(throwing: error)
            } catch is CancellationError {
                continuation.finish()
            } catch {
                continuation.finish(throwing: AIError.networkError(error))
            }
        }
    }
}
