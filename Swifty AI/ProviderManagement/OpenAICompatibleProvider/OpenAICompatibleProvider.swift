import Foundation

public struct OpenAICompatibleProvider: AIModel, AIStreamModel {
    private let baseURL: String
    private let apiKey: String
    private let model: String
    let session: URLSession

    public init(baseURL: String, apiKey: String, model: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.model = model
        self.session = session
    }

    public func generate(_ prompt: String) async throws -> AIResponse {
        try await generate(prompt, options: GenerationOptions())
    }

    public func generate(_ prompt: String, options: GenerationOptions) async throws -> AIResponse {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw AIError.invalidResponse
        }
        let headers = ["Authorization": "Bearer \(apiKey)"]
        var messages: [Request.Message] = []
        if let system = options.system {
            messages.append(.init(role: "system", content: system))
        }
        messages.append(.init(role: "user", content: prompt))

        let body = Request(
            model: model,
            messages: messages,
            stream: false,
            streamOptions: nil,
            temperature: options.temperature,
            topP: options.topP,
            maxTokens: options.maxTokens,
            seed: options.seed,
            presencePenalty: options.presencePenalty,
            frequencyPenalty: options.frequencyPenalty,
            stop: options.stopSequences
        )

        let data = try await httpPost(url: url, headers: headers, body: body, session: session)

        do {
            let decoded = try JSONDecoder().decode(Response.self, from: data)
            guard let choice = decoded.choices.first else {
                throw AIError.invalidResponse
            }
            let usage = decoded.usage.map {
                TokenUsage(inputTokens: $0.promptTokens, outputTokens: $0.completionTokens)
            }
            return AIResponse(
                text: choice.message?.content ?? "",
                model: decoded.model,
                usage: usage,
                finishReason: choice.finishReason
            )
        } catch let error as AIError {
            throw error
        } catch {
            throw AIError.decodingError(error)
        }
    }

    public func stream(messages: [ChatMessage]) -> AsyncThrowingStream<AIStreamChunk, Error> {
        streamSSE(messages: messages.map { .init(role: $0.role.rawValue, content: $0.content) }, options: GenerationOptions())
    }

    public func stream(_ prompt: String) -> AsyncThrowingStream<AIStreamChunk, Error> {
        stream(prompt, options: GenerationOptions())
    }

    public func stream(_ prompt: String, options: GenerationOptions) -> AsyncThrowingStream<AIStreamChunk, Error> {
        var messages: [Request.Message] = []
        if let system = options.system {
            messages.append(.init(role: "system", content: system))
        }
        messages.append(.init(role: "user", content: prompt))
        return streamSSE(messages: messages, options: options)
    }

    private func streamSSE(messages: [Request.Message], options: GenerationOptions) -> AsyncThrowingStream<AIStreamChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                guard let url = URL(string: "\(baseURL)/chat/completions") else {
                    continuation.finish(throwing: AIError.invalidResponse)
                    return
                }

                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

                let body = Request(
                    model: model,
                    messages: messages,
                    stream: true,
                    streamOptions: .init(includeUsage: true),
                    temperature: options.temperature,
                    topP: options.topP,
                    maxTokens: options.maxTokens,
                    seed: options.seed,
                    presencePenalty: options.presencePenalty,
                    frequencyPenalty: options.frequencyPenalty,
                    stop: options.stopSequences
                )
                do {
                    request.httpBody = try JSONEncoder().encode(body)
                } catch {
                    continuation.finish(throwing: AIError.encodingError(error))
                    return
                }

                do {
                    for try await jsonString in sseLines(request: request, session: session) {
                        if Task.isCancelled {
                            continuation.finish()
                            return
                        }
                        guard let data = jsonString.data(using: .utf8) else { continue }
                        do {
                            let chunk = try JSONDecoder().decode(StreamChunk.self, from: data)

                            if let u = chunk.usage, chunk.choices.isEmpty {
                                let usage = TokenUsage(inputTokens: u.promptTokens, outputTokens: u.completionTokens)
                                continuation.yield(AIStreamChunk(text: "", finishReason: nil, usage: usage))
                                continue
                            }

                            guard let choice = chunk.choices.first else { continue }
                            let text = choice.delta?.content ?? ""
                            let finishReason = choice.finishReason

                            if finishReason != nil {
                                continuation.yield(AIStreamChunk(text: text, finishReason: finishReason, usage: nil))
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

private extension OpenAICompatibleProvider {
    struct Request: Encodable {
        let model: String
        let messages: [Message]
        let stream: Bool
        let streamOptions: StreamOptions?
        let temperature: Double?
        let topP: Double?
        let maxTokens: Int?
        let seed: Int?
        let presencePenalty: Double?
        let frequencyPenalty: Double?
        let stop: [String]?

        enum CodingKeys: String, CodingKey {
            case model, messages, stream
            case streamOptions = "stream_options"
            case temperature
            case topP = "top_p"
            case maxTokens = "max_tokens"
            case seed
            case presencePenalty = "presence_penalty"
            case frequencyPenalty = "frequency_penalty"
            case stop
        }

        struct Message: Encodable {
            let role: String
            let content: String
        }

        struct StreamOptions: Encodable {
            let includeUsage: Bool

            enum CodingKeys: String, CodingKey {
                case includeUsage = "include_usage"
            }
        }
    }

    struct Response: Decodable {
        let model: String?
        let choices: [Choice]
        let usage: Usage?

        struct Choice: Decodable {
            let message: Message?
            let finishReason: String?

            enum CodingKeys: String, CodingKey {
                case message
                case finishReason = "finish_reason"
            }

            struct Message: Decodable {
                let content: String
            }
        }

        struct Usage: Decodable {
            let promptTokens: Int
            let completionTokens: Int

            enum CodingKeys: String, CodingKey {
                case promptTokens = "prompt_tokens"
                case completionTokens = "completion_tokens"
            }
        }
    }

    struct StreamChunk: Decodable {
        let choices: [StreamChoice]
        let usage: StreamUsage?

        struct StreamChoice: Decodable {
            let delta: Delta?
            let finishReason: String?

            enum CodingKeys: String, CodingKey {
                case delta
                case finishReason = "finish_reason"
            }

            struct Delta: Decodable {
                let content: String?
            }
        }

        struct StreamUsage: Decodable {
            let promptTokens: Int
            let completionTokens: Int

            enum CodingKeys: String, CodingKey {
                case promptTokens = "prompt_tokens"
                case completionTokens = "completion_tokens"
            }
        }
    }
}
