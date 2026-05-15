import Foundation

public struct OpenAICompatibleProvider: AIModel, AIStreamModel, AIToolCallingModel, AIImageModel, AITranscriptionModel, AISpeechModel, AIVideoModel {
    let baseURL: String
    let apiKey: String
    let model: String
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
        try await generate([.text(prompt)], options: options)
    }

    public func generate(_ prompt: [AIMessageContent], options: GenerationOptions) async throws -> AIResponse {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw AIError.invalidResponse
        }
        let headers = ["Authorization": "Bearer \(apiKey)"]
        var messages: [Request.Message] = []
        if let system = options.system {
            messages.append(.init(role: "system", content: system))
        }
        messages.append(.init(role: "user", parts: prompt))

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

        let data = try await httpPost(url: url, headers: headers, body: body, session: session, options: options)

        do {
            let decoded = try JSONDecoder().decode(Response.self, from: data)
            guard let choice = decoded.choices.first else {
                throw AIError.invalidResponse
            }
            let usage = decoded.usage.map {
                TokenUsage(
                    inputTokens: $0.promptTokens,
                    outputTokens: $0.completionTokens,
                    totalTokens: $0.totalTokens,
                    cachedInputTokens: $0.promptTokensDetails?.cachedTokens
                )
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
        streamSSE(messages: messages.map { .init(role: $0.role.rawValue, parts: $0.parts) }, options: GenerationOptions())
    }

    public func stream(_ prompt: String) -> AsyncThrowingStream<AIStreamChunk, Error> {
        stream(prompt, options: GenerationOptions())
    }

    public func stream(_ prompt: String, options: GenerationOptions) -> AsyncThrowingStream<AIStreamChunk, Error> {
        stream([.text(prompt)], options: options)
    }

    public func stream(_ prompt: [AIMessageContent], options: GenerationOptions) -> AsyncThrowingStream<AIStreamChunk, Error> {
        var messages: [Request.Message] = []
        if let system = options.system {
            messages.append(.init(role: "system", content: system))
        }
        messages.append(.init(role: "user", parts: prompt))
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
                    for try await jsonString in sseLines(request: request, session: session, options: options) {
                        if Task.isCancelled {
                            continuation.finish()
                            return
                        }
                        guard let data = jsonString.data(using: .utf8) else { continue }
                        do {
                            let chunk = try JSONDecoder().decode(StreamChunk.self, from: data)

                            if let u = chunk.usage, chunk.choices.isEmpty {
                                let usage = TokenUsage(
                                    inputTokens: u.promptTokens,
                                    outputTokens: u.completionTokens,
                                    totalTokens: u.totalTokens,
                                    cachedInputTokens: u.promptTokensDetails?.cachedTokens
                                )
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

    public func generateStep(
        messages: [AIAgentMessage],
        tools: [AITool],
        options: GenerationOptions
    ) async throws -> AIToolStepResponse {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw AIError.invalidResponse
        }

        let body = Request(
            model: model,
            messages: messages.map { Request.Message(agentMessage: $0) },
            stream: false,
            streamOptions: nil,
            temperature: options.temperature,
            topP: options.topP,
            maxTokens: options.maxTokens,
            seed: options.seed,
            presencePenalty: options.presencePenalty,
            frequencyPenalty: options.frequencyPenalty,
            stop: options.stopSequences,
            tools: tools.isEmpty ? nil : tools.map { Request.Tool(tool: $0) },
            toolChoice: tools.isEmpty ? nil : "auto",
            promptCacheKey: options.promptCaching?.cacheKey,
            promptCacheRetention: options.promptCaching?.retention
        )

        let data = try await httpPost(
            url: url,
            headers: ["Authorization": "Bearer \(apiKey)"],
            body: body,
            session: session,
            options: options
        )

        do {
            let decoded = try JSONDecoder().decode(Response.self, from: data)
            guard let choice = decoded.choices.first else {
                throw AIError.invalidResponse
            }
            let usage = decoded.usage.map {
                TokenUsage(
                    inputTokens: $0.promptTokens,
                    outputTokens: $0.completionTokens,
                    totalTokens: $0.totalTokens,
                    cachedInputTokens: $0.promptTokensDetails?.cachedTokens
                )
            }
            let calls = choice.message?.toolCalls?.map {
                AIToolCall(id: $0.id, name: $0.function.name, arguments: $0.function.arguments)
            } ?? []
            return AIToolStepResponse(
                text: choice.message?.content ?? "",
                toolCalls: calls,
                usage: usage,
                finishReason: choice.finishReason,
                model: decoded.model
            )
        } catch let error as AIError {
            throw error
        } catch {
            throw AIError.decodingError(error)
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
        let tools: [Tool]?
        let toolChoice: String?
        let promptCacheKey: String?
        let promptCacheRetention: String?

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
            case tools
            case toolChoice = "tool_choice"
            case promptCacheKey = "prompt_cache_key"
            case promptCacheRetention = "prompt_cache_retention"
        }

        init(
            model: String,
            messages: [Message],
            stream: Bool,
            streamOptions: StreamOptions?,
            temperature: Double?,
            topP: Double?,
            maxTokens: Int?,
            seed: Int?,
            presencePenalty: Double?,
            frequencyPenalty: Double?,
            stop: [String]?,
            tools: [Tool]? = nil,
            toolChoice: String? = nil,
            promptCacheKey: String? = nil,
            promptCacheRetention: String? = nil
        ) {
            self.model = model
            self.messages = messages
            self.stream = stream
            self.streamOptions = streamOptions
            self.temperature = temperature
            self.topP = topP
            self.maxTokens = maxTokens
            self.seed = seed
            self.presencePenalty = presencePenalty
            self.frequencyPenalty = frequencyPenalty
            self.stop = stop
            self.tools = tools
            self.toolChoice = toolChoice
            self.promptCacheKey = promptCacheKey
            self.promptCacheRetention = promptCacheRetention
        }

        struct Message: Encodable {
            let role: String
            let content: MessageContent?
            let toolCalls: [ToolCall]?
            let toolCallID: String?
            let name: String?

            enum CodingKeys: String, CodingKey {
                case role, content, name
                case toolCalls = "tool_calls"
                case toolCallID = "tool_call_id"
            }

            init(role: String, content: String? = nil, toolCalls: [ToolCall]? = nil, toolCallID: String? = nil, name: String? = nil) {
                self.role = role
                self.content = content.map(MessageContent.string)
                self.toolCalls = toolCalls
                self.toolCallID = toolCallID
                self.name = name
            }

            init(role: String, parts: [AIMessageContent]) {
                self.role = role
                if parts.count == 1, case .text(let text) = parts[0] {
                    self.content = .string(text)
                } else {
                    self.content = .parts(parts.map(ContentPart.init(content:)))
                }
                self.toolCalls = nil
                self.toolCallID = nil
                self.name = nil
            }

            init(agentMessage: AIAgentMessage) {
                self.role = agentMessage.role
                self.content = agentMessage.content.map(MessageContent.string)
                self.toolCalls = agentMessage.toolCalls.isEmpty ? nil : agentMessage.toolCalls.map(ToolCall.init(toolCall:))
                self.toolCallID = agentMessage.toolCallID
                self.name = agentMessage.name
            }
        }

        enum MessageContent: Encodable {
            case string(String)
            case parts([ContentPart])

            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case .string(let string):
                    try container.encode(string)
                case .parts(let parts):
                    try container.encode(parts)
                }
            }
        }

        struct ContentPart: Encodable {
            let type: String
            let text: String?
            let imageURL: ImageURL?
            let file: FilePart?
            let inputAudio: InputAudio?
            let videoURL: String?

            enum CodingKeys: String, CodingKey {
                case type, text, file
                case imageURL = "image_url"
                case inputAudio = "input_audio"
                case videoURL = "video_url"
            }

            init(content: AIMessageContent) {
                switch content {
                case .text(let text):
                    self.type = "text"
                    self.text = text
                    self.imageURL = nil
                    self.file = nil
                    self.inputAudio = nil
                    self.videoURL = nil
                case .imageURL(let url, let detail):
                    self.type = "image_url"
                    self.text = nil
                    self.imageURL = ImageURL(url: url.absoluteString, detail: detail)
                    self.file = nil
                    self.inputAudio = nil
                    self.videoURL = nil
                case .imageBase64, .imageData:
                    self.type = "image_url"
                    self.text = nil
                    self.imageURL = ImageURL(url: content.dataURL ?? "", detail: Self.imageDetail(content))
                    self.file = nil
                    self.inputAudio = nil
                    self.videoURL = nil
                case .pdfURL(let url, let filename):
                    self.type = "file"
                    self.text = nil
                    self.imageURL = nil
                    self.file = FilePart(filename: filename ?? url.lastPathComponent, fileData: nil, fileURL: url.absoluteString)
                    self.inputAudio = nil
                    self.videoURL = nil
                case .pdfBase64, .pdfData, .fileBase64, .fileData:
                    self.type = "file"
                    self.text = nil
                    self.imageURL = nil
                    self.file = FilePart(filename: content.filename ?? "attachment", fileData: content.dataURL, fileURL: nil)
                    self.inputAudio = nil
                    self.videoURL = nil
                case .audioBase64(let base64, let mediaType, _):
                    self.type = "input_audio"
                    self.text = nil
                    self.imageURL = nil
                    self.file = nil
                    self.inputAudio = InputAudio(data: base64, format: mediaType.audioFormat)
                    self.videoURL = nil
                case .audioData(let data, let mediaType, _):
                    self.type = "input_audio"
                    self.text = nil
                    self.imageURL = nil
                    self.file = nil
                    self.inputAudio = InputAudio(data: data.base64EncodedString(), format: mediaType.audioFormat)
                    self.videoURL = nil
                case .videoURL(let url):
                    self.type = "video_url"
                    self.text = nil
                    self.imageURL = nil
                    self.file = nil
                    self.inputAudio = nil
                    self.videoURL = url.absoluteString
                case .videoBase64, .videoData:
                    self.type = "video_url"
                    self.text = nil
                    self.imageURL = nil
                    self.file = nil
                    self.inputAudio = nil
                    self.videoURL = content.dataURL
                case .fileURL(let url, _, let filename):
                    self.type = "file"
                    self.text = nil
                    self.imageURL = nil
                    self.file = FilePart(filename: filename ?? url.lastPathComponent, fileData: nil, fileURL: url.absoluteString)
                    self.inputAudio = nil
                    self.videoURL = nil
                }
            }

            private static func imageDetail(_ content: AIMessageContent) -> ImageDetail? {
                switch content {
                case .imageBase64(_, _, let detail), .imageData(_, _, let detail):
                    return detail
                default:
                    return nil
                }
            }

            struct ImageURL: Encodable {
                let url: String
                let detail: ImageDetail?
            }

            struct FilePart: Encodable {
                let filename: String
                let fileData: String?
                let fileURL: String?

                enum CodingKeys: String, CodingKey {
                    case filename
                    case fileData = "file_data"
                    case fileURL = "file_url"
                }
            }

            struct InputAudio: Encodable {
                let data: String
                let format: String
            }
        }

        struct Tool: Encodable {
            let type = "function"
            let function: Function

            init(tool: AITool) {
                self.function = Function(tool: tool)
            }

            struct Function: Encodable {
                let name: String
                let description: String
                let parameters: AIJSONValue

                init(tool: AITool) {
                    self.name = tool.name
                    self.description = tool.description
                    self.parameters = AIJSONValue(value: tool.parameters)
                }
            }
        }

        struct ToolCall: Encodable {
            let id: String
            let type = "function"
            let function: Function

            init(toolCall: AIToolCall) {
                self.id = toolCall.id
                self.function = Function(name: toolCall.name, arguments: toolCall.arguments)
            }

            struct Function: Encodable {
                let name: String
                let arguments: String
            }
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
                let content: String?
                let toolCalls: [ToolCall]?

                enum CodingKeys: String, CodingKey {
                    case content
                    case toolCalls = "tool_calls"
                }
            }
        }

        struct Usage: Decodable {
            let promptTokens: Int
            let completionTokens: Int
            let totalTokens: Int?
            let promptTokensDetails: PromptTokensDetails?

            enum CodingKeys: String, CodingKey {
                case promptTokens = "prompt_tokens"
                case completionTokens = "completion_tokens"
                case totalTokens = "total_tokens"
                case promptTokensDetails = "prompt_tokens_details"
            }

            struct PromptTokensDetails: Decodable {
                let cachedTokens: Int?

                enum CodingKeys: String, CodingKey {
                    case cachedTokens = "cached_tokens"
                }
            }
        }

        struct ToolCall: Decodable {
            let id: String
            let function: Function

            struct Function: Decodable {
                let name: String
                let arguments: String
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
            let totalTokens: Int?
            let promptTokensDetails: PromptTokensDetails?

            enum CodingKeys: String, CodingKey {
                case promptTokens = "prompt_tokens"
                case completionTokens = "completion_tokens"
                case totalTokens = "total_tokens"
                case promptTokensDetails = "prompt_tokens_details"
            }

            struct PromptTokensDetails: Decodable {
                let cachedTokens: Int?

                enum CodingKeys: String, CodingKey {
                    case cachedTokens = "cached_tokens"
                }
            }
        }
    }
}
