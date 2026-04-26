import Foundation

public struct OpenAIProvider: AIModel {
    private let apiKey: String
    private let model: String

    init(apiKey: String, model: String) {
        self.apiKey = apiKey
        self.model = model
    }

    public func generate(_ prompt: String) async throws -> AIResponse {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        let headers = ["Authorization": "Bearer \(apiKey)"]
        let body = Request(
            model: model,
            messages: [.init(role: "user", content: prompt)]
        )

        let data = try await httpPost(url: url, headers: headers, body: body)

        do {
            let decoded = try JSONDecoder().decode(Response.self, from: data)
            guard let text = decoded.choices.first?.message.content else {
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

private extension OpenAIProvider {
    struct Request: Encodable {
        let model: String
        let messages: [Message]

        struct Message: Encodable {
            let role: String
            let content: String
        }
    }

    struct Response: Decodable {
        let choices: [Choice]

        struct Choice: Decodable {
            let message: Message

            struct Message: Decodable {
                let content: String
            }
        }
    }
}
