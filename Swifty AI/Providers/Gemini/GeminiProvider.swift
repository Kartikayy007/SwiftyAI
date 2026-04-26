import Foundation

public struct GeminiProvider: AIModel, AIStreamModel {
    private let apiKey: String
    private let model: String
    let session: URLSession

    public init(apiKey: String, model: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.model = model
        self.session = session
    }

    public func generate(_ prompt: String) async throws -> AIResponse {
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent"
        guard let url = URL(string: urlString) else {
            throw AIError.invalidResponse
        }
        let headers = ["x-goog-api-key": apiKey]
        let body = Request(contents: [.init(parts: [.init(text: prompt)])])

        let data = try await httpPost(url: url, headers: headers, body: body, session: session)

        do {
            let decoded = try JSONDecoder().decode(Response.self, from: data)
            guard let text = decoded.candidates.first?.content.parts.first?.text else {
                throw AIError.invalidResponse
            }
            let usage = decoded.usageMetadata.map {
                TokenUsage(inputTokens: $0.promptTokenCount, outputTokens: $0.candidatesTokenCount)
            }
            return AIResponse(
                text: text,
                model: decoded.modelVersion,
                usage: usage,
                finishReason: decoded.candidates.first?.finishReason
            )
        } catch let error as AIError {
            throw error
        } catch {
            throw AIError.decodingError(error)
        }
    }

    public func stream(_ prompt: String) -> AsyncThrowingStream<AIStreamChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):streamGenerateContent?alt=sse"
                guard let url = URL(string: urlString) else {
                    continuation.finish(throwing: AIError.invalidResponse)
                    return
                }

                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

                let body = Request(contents: [.init(parts: [.init(text: prompt)])])
                do {
                    request.httpBody = try JSONEncoder().encode(body)
                } catch {
                    continuation.finish(throwing: AIError.encodingError(error))
                    return
                }

                var lastUsage: TokenUsage?

                do {
                    for try await jsonString in sseLines(request: request, session: session) {
                        if Task.isCancelled {
                            continuation.finish()
                            return
                        }
                        guard let data = jsonString.data(using: .utf8) else { continue }
                        do {
                            let chunk = try JSONDecoder().decode(Response.self, from: data)
                            let text = chunk.candidates.first?.content.parts.first?.text ?? ""
                            let finishReason = chunk.candidates.first?.finishReason

                            if let meta = chunk.usageMetadata {
                                lastUsage = TokenUsage(inputTokens: meta.promptTokenCount, outputTokens: meta.candidatesTokenCount)
                            }

                            if finishReason != nil {
                                continuation.yield(AIStreamChunk(text: text, finishReason: finishReason, usage: lastUsage))
                            } else if !text.isEmpty {
                                continuation.yield(AIStreamChunk(text: text, finishReason: nil, usage: nil))
                            }
                        } catch {
                            continue
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

private extension GeminiProvider {
    struct Request: Encodable {
        let contents: [Content]

        struct Content: Encodable {
            let parts: [Part]

            struct Part: Encodable {
                let text: String
            }
        }
    }

    struct Response: Decodable {
        let candidates: [Candidate]
        let usageMetadata: UsageMetadata?
        let modelVersion: String?

        struct Candidate: Decodable {
            let content: Content
            let finishReason: String?

            enum CodingKeys: String, CodingKey {
                case content
                case finishReason = "finishReason"
            }

            struct Content: Decodable {
                let parts: [Part]

                struct Part: Decodable {
                    let text: String
                }
            }
        }

        struct UsageMetadata: Decodable {
            let promptTokenCount: Int
            let candidatesTokenCount: Int
        }
    }
}
