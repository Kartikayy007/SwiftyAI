import Foundation

public struct AnthropicProvider: AIModel {
    private let apiKey: String
    private let model: String

    init(apiKey: String, model: String) {
        self.apiKey = apiKey
        self.model = model
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
            messages: [.init(role: "user", content: prompt)]
        )

        let data = try await httpPost(url: url, headers: headers, body: body)

        do {
            let decoded = try JSONDecoder().decode(Response.self, from: data)
            guard let text = decoded.content.first?.text else {
                throw AIError.invalidResponse
            }
            return AIResponse(text: text)
        } catch let error as AIError {
            throw error
        } catch {
            throw AIError.decodingError(error)
        }
    }
}

private extension AnthropicProvider {
    struct Request: Encodable {
        let model: String
        let maxTokens: Int
        let messages: [Message]

        enum CodingKeys: String, CodingKey {
            case model
            case maxTokens = "max_tokens"
            case messages
        }

        struct Message: Encodable {
            let role: String
            let content: String
        }
    }

    struct Response: Decodable {
        let content: [ContentBlock]

        struct ContentBlock: Decodable {
            let type: String
            let text: String
        }
    }
}
