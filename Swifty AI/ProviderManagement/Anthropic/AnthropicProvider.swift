import Foundation

public struct AnthropicProvider: AIModel, AIStreamModel, AIToolCallingModel {
    private let apiKey: String
    private let model: String
    let session: URLSession

    public init(apiKey: String, model: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.model = model
        self.session = session
    }

    public func generate(_ prompt: String) async throws -> AIResponse {
        try await generate(prompt, options: GenerationOptions())
    }

    public func generate(_ prompt: String, options: GenerationOptions) async throws -> AIResponse {
        try await generate([.text(prompt)], options: options)
    }

    public func generate(_ prompt: [AIMessageContent], options: GenerationOptions) async throws -> AIResponse {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        let headers = [
            "x-api-key": apiKey,
            "anthropic-version": "2023-06-01"
        ]
        let body = Request(
            model: model,
            maxTokens: options.maxTokens ?? 1024,
            messages: [.init(role: "user", content: try Request.ContentBlock.blocks(from: prompt))],
            system: options.system,
            stream: false,
            temperature: options.temperature,
            topP: options.topP,
            topK: options.topK,
            stopSequences: options.stopSequences
        )

        let data = try await httpPost(url: url, headers: headers, body: body, session: session, options: options)

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

    public func stream(messages: [ChatMessage]) -> AsyncThrowingStream<AIStreamChunk, Error> {
        let system = messages.first(where: { $0.role == .system })?.content
        let convo: [Request.Message]
        do {
            convo = try messages
                .filter { $0.role != .system }
                .map { try Request.Message(role: $0.role.rawValue, content: Request.ContentBlock.blocks(from: $0.parts)) }
        } catch {
            return AsyncThrowingStream { $0.finish(throwing: error) }
        }
        return streamSSE(messages: convo, system: system, options: GenerationOptions())
    }

    public func stream(_ prompt: String) -> AsyncThrowingStream<AIStreamChunk, Error> {
        stream(prompt, options: GenerationOptions())
    }

    public func stream(_ prompt: String, options: GenerationOptions) -> AsyncThrowingStream<AIStreamChunk, Error> {
        stream([.text(prompt)], options: options)
    }

    public func stream(_ prompt: [AIMessageContent], options: GenerationOptions) -> AsyncThrowingStream<AIStreamChunk, Error> {
        do {
            return streamSSE(
                messages: [.init(role: "user", content: try Request.ContentBlock.blocks(from: prompt))],
                system: options.system,
                options: options
            )
        } catch {
            return AsyncThrowingStream { $0.finish(throwing: error) }
        }
    }

    private func streamSSE(messages: [Request.Message], system: String?, options: GenerationOptions) -> AsyncThrowingStream<AIStreamChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
                request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

                let body = Request(
                    model: model,
                    maxTokens: options.maxTokens ?? 1024,
                    messages: messages,
                    system: system,
                    stream: true,
                    temperature: options.temperature,
                    topP: options.topP,
                    topK: options.topK,
                    stopSequences: options.stopSequences
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
                    for try await jsonString in sseLines(request: request, session: session, options: options) {
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
        let system: String?
        let stream: Bool
        let temperature: Double?
        let topP: Double?
        let topK: Int?
        let stopSequences: [String]?

        enum CodingKeys: String, CodingKey {
            case model
            case maxTokens = "max_tokens"
            case messages
            case system
            case stream
            case temperature
            case topP = "top_p"
            case topK = "top_k"
            case stopSequences = "stop_sequences"
        }

        struct Message: Encodable {
            let role: String
            let content: [ContentBlock]
        }

        struct ContentBlock: Encodable {
            let type: String
            let text: String?
            let source: Source?

            static func blocks(from parts: [AIMessageContent]) throws -> [ContentBlock] {
                try parts.map(ContentBlock.init(content:))
            }

            init(content: AIMessageContent) throws {
                switch content {
                case .text(let text):
                    self.type = "text"
                    self.text = text
                    self.source = nil
                case .imageURL(let url, _):
                    self.type = "image"
                    self.text = nil
                    self.source = .url(url.absoluteString)
                case .imageBase64, .imageData:
                    guard let mediaType = content.mediaType, let data = content.rawBase64 else {
                        throw AIError.invalidResponse
                    }
                    self.type = "image"
                    self.text = nil
                    self.source = .base64(mediaType: mediaType.rawValue, data: data)
                case .pdfURL(let url, _):
                    self.type = "document"
                    self.text = nil
                    self.source = .url(url.absoluteString)
                case .pdfBase64, .pdfData:
                    guard let data = content.rawBase64 else { throw AIError.invalidResponse }
                    self.type = "document"
                    self.text = nil
                    self.source = .base64(mediaType: AIMediaType.pdf.rawValue, data: data)
                default:
                    throw AIError.unsupportedFeature("Anthropic multimodal requests support text, images, and PDFs in this SDK")
                }
            }

            enum CodingKeys: String, CodingKey {
                case type, text, source
            }

            struct Source: Encodable {
                let type: String
                let url: String?
                let mediaType: String?
                let data: String?

                enum CodingKeys: String, CodingKey {
                    case type, url, data
                    case mediaType = "media_type"
                }

                static func url(_ url: String) -> Source {
                    Source(type: "url", url: url, mediaType: nil, data: nil)
                }

                static func base64(mediaType: String, data: String) -> Source {
                    Source(type: "base64", url: nil, mediaType: mediaType, data: data)
                }
            }
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
