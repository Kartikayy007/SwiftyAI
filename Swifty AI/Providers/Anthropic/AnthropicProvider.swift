import Foundation

public struct AnthropicProvider: AIModel, AIStreamModel {
    private let apiKey: String
    private let model: String
    let session: URLSession

    public init(apiKey: String, model: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.model = model
        self.session = session
    }

    public func generate(_ prompt: String) async throws -> AIResponse {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        let headers = [
            "x-api-key": apiKey,
            "anthropic-version": "2023-06-01"
        ]
        let body = Request(
            model: model,
            maxTokens: 1024,
            messages: [.init(role: "user", content: prompt)],
            stream: false
        )

        let data = try await httpPost(url: url, headers: headers, body: body, session: session)

        do {
            let decoded = try JSONDecoder().decode(Response.self, from: data)
            guard let text = decoded.content.first(where: { $0.type == "text" })?.text else {
                throw AIError.invalidResponse
            }
            let usage = decoded.usage.map {
                TokenUsage(inputTokens: $0.inputTokens, outputTokens: $0.outputTokens)
            }
            return AIResponse(
                text: text,
                model: decoded.model,
                usage: usage,
                finishReason: decoded.stopReason
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
                var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
                request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

                let body = Request(
                    model: model,
                    maxTokens: 1024,
                    messages: [.init(role: "user", content: prompt)],
                    stream: true
                )
                do {
                    request.httpBody = try JSONEncoder().encode(body)
                } catch {
                    continuation.finish(throwing: AIError.encodingError(error))
                    return
                }

                var inputTokens: Int?
                var outputTokens: Int?

                do {
                    for try await jsonString in sseLines(request: request, session: session) {
                        if Task.isCancelled {
                            continuation.finish()
                            return
                        }
                        guard let data = jsonString.data(using: .utf8) else { continue }

                        if let delta = try? JSONDecoder().decode(ContentBlockDeltaEvent.self, from: data),
                           delta.type == "content_block_delta",
                           delta.delta.type == "text_delta",
                           let text = delta.delta.text {
                            continuation.yield(AIStreamChunk(text: text, finishReason: nil, usage: nil))
                            continue
                        }

                        if let start = try? JSONDecoder().decode(MessageStartEvent.self, from: data),
                           start.type == "message_start" {
                            inputTokens = start.message.usage?.inputTokens
                            continue
                        }

                        if let msgDelta = try? JSONDecoder().decode(MessageDeltaEvent.self, from: data),
                           msgDelta.type == "message_delta" {
                            outputTokens = msgDelta.usage?.outputTokens
                            let finishReason = msgDelta.delta.stopReason
                            let usage: TokenUsage? = inputTokens.flatMap { i in
                                outputTokens.map { o in TokenUsage(inputTokens: i, outputTokens: o) }
                            }
                            continuation.yield(AIStreamChunk(text: "", finishReason: finishReason, usage: usage))
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

private extension AnthropicProvider {
    struct Request: Encodable {
        let model: String
        let maxTokens: Int
        let messages: [Message]
        let stream: Bool

        enum CodingKeys: String, CodingKey {
            case model
            case maxTokens = "max_tokens"
            case messages
            case stream
        }

        struct Message: Encodable {
            let role: String
            let content: String
        }
    }

    struct Response: Decodable {
        let model: String?
        let content: [ContentBlock]
        let stopReason: String?
        let usage: Usage?

        enum CodingKeys: String, CodingKey {
            case model, content
            case stopReason = "stop_reason"
            case usage
        }

        struct ContentBlock: Decodable {
            let type: String
            let text: String?
        }

        struct Usage: Decodable {
            let inputTokens: Int
            let outputTokens: Int

            enum CodingKeys: String, CodingKey {
                case inputTokens = "input_tokens"
                case outputTokens = "output_tokens"
            }
        }
    }

    struct ContentBlockDeltaEvent: Decodable {
        let type: String
        let delta: Delta

        struct Delta: Decodable {
            let type: String
            let text: String?
        }
    }

    struct MessageStartEvent: Decodable {
        let type: String
        let message: MessagePayload

        struct MessagePayload: Decodable {
            let usage: Usage?

            struct Usage: Decodable {
                let inputTokens: Int

                enum CodingKeys: String, CodingKey {
                    case inputTokens = "input_tokens"
                }
            }
        }
    }

    struct MessageDeltaEvent: Decodable {
        let type: String
        let delta: Delta
        let usage: Usage?

        struct Delta: Decodable {
            let stopReason: String?

            enum CodingKeys: String, CodingKey {
                case stopReason = "stop_reason"
            }
        }

        struct Usage: Decodable {
            let outputTokens: Int

            enum CodingKeys: String, CodingKey {
                case outputTokens = "output_tokens"
            }
        }
    }
}
