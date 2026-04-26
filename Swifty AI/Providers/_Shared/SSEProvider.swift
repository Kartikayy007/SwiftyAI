import Foundation

func sseLines(request: URLRequest, session: URLSession = .shared) -> AsyncThrowingStream<String, Error> {
    AsyncThrowingStream { continuation in
        Task {
            do {
                let (data, response) = try await session.data(for: request)

                guard let http = response as? HTTPURLResponse else {
                    continuation.finish(throwing: AIError.invalidResponse)
                    return
                }

                guard (200..<300).contains(http.statusCode) else {
                    let message = apiSSEErrorMessage(from: data) ?? "HTTP \(http.statusCode)"
                    continuation.finish(throwing: AIError.apiError(statusCode: http.statusCode, message: message))
                    return
                }

                guard let body = String(data: data, encoding: .utf8) else {
                    continuation.finish(throwing: AIError.invalidResponse)
                    return
                }

                let lines = body.components(separatedBy: "\n")

                for line in lines {
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
            } catch {
                continuation.finish(throwing: AIError.networkError(error))
            }
        }
    }
}

private func apiSSEErrorMessage(from data: Data) -> String? {
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        return String(data: data, encoding: .utf8)
    }
    if let error = json["error"] as? [String: Any], let msg = error["message"] as? String {
        return msg
    }
    if let message = json["message"] as? String { return message }
    return String(data: data, encoding: .utf8)
}
