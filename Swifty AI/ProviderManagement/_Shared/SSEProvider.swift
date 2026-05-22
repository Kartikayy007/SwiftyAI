import Foundation

func sseLines(
    request: URLRequest,
    session: URLSession = .shared,
    options: GenerationOptions = GenerationOptions()
) -> AsyncThrowingStream<String, Error> {
    AsyncThrowingStream { continuation in
        Task {
            var request = request
            for (key, value) in options.headers {
                request.setValue(value, forHTTPHeaderField: key)
            }

            let policy = options.retryPolicy
            let maxAttempts = max(1, policy.maxAttempts)
            var lastError: Error?

            for attempt in 1...maxAttempts {
                if Task.isCancelled {
                    continuation.finish()
                    return
                }

                do {
                    let (bytes, response) = try await session.bytes(for: request)

                    guard let http = response as? HTTPURLResponse else {
                        throw AIError.invalidResponse
                    }

                    guard (200..<300).contains(http.statusCode) else {
                        // Drain body to parse provider error message.
                        var data = Data()
                        do {
                            for try await byte in bytes {
                                data.append(byte)
                                if data.count > 64_000 { break }
                            }
                        } catch {
                            // Body read failure: fall through with empty data.
                        }
                        let message = apiErrorMessage(from: data) ?? "HTTP \(http.statusCode)"
                        let apiError = AIError.apiError(statusCode: http.statusCode, message: message)
                        if shouldRetry(apiError, policy: policy), attempt < maxAttempts {
                            lastError = apiError
                            try await Task.sleep(for: policy.delay(forAttempt: attempt))
                            continue
                        }
                        throw apiError
                    }

                    // 2xx — start streaming. Retries are off from this point on.
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
                    return
                } catch let error as AIError {
                    if shouldRetry(error, policy: policy), attempt < maxAttempts {
                        lastError = error
                        try? await Task.sleep(for: policy.delay(forAttempt: attempt))
                        continue
                    }
                    continuation.finish(throwing: error)
                    return
                } catch is CancellationError {
                    continuation.finish()
                    return
                } catch {
                    let wrapped = AIError.networkError(error)
                    if shouldRetry(wrapped, policy: policy), attempt < maxAttempts {
                        lastError = wrapped
                        try? await Task.sleep(for: policy.delay(forAttempt: attempt))
                        continue
                    }
                    continuation.finish(throwing: wrapped)
                    return
                }
            }

            continuation.finish(throwing: lastError ?? AIError.invalidResponse)
        }
    }
}
