import Foundation

public struct OpenAICompatibleProvider: AIModel {
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
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw AIError.invalidResponse
        }
        let headers = ["Authorization": "Bearer \(apiKey)"]
        let body = Request(
            model: model,
            messages: [.init(role: "user", content: prompt)]
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
                text: choice.message.content,
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
}

private extension OpenAICompatibleProvider {
    struct Request: Encodable {
        let model: String
        let messages: [Message]

        struct Message: Encodable {
            let role: String
            let content: String
        }
    }

    struct Response: Decodable {
        let model: String?
        let choices: [Choice]
        let usage: Usage?

        struct Choice: Decodable {
            let message: Message
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
}
