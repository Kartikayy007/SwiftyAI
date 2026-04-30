import Foundation

public protocol AIToolCallingModel: AIStreamModel {
    func generateStep(
        messages: [AIAgentMessage],
        tools: [AITool],
        options: GenerationOptions
    ) async throws -> AIToolStepResponse
}

public extension AIToolCallingModel {
    func generateStep(
        messages: [AIAgentMessage],
        tools: [AITool],
        options: GenerationOptions
    ) async throws -> AIToolStepResponse {
        let response = try await generate(promptToolLoopPrompt(messages: messages, tools: tools), options: options)
        let decoded = try decodePromptToolResponse(response.text)
        return AIToolStepResponse(
            text: decoded.text,
            toolCalls: decoded.toolCalls.map {
                AIToolCall(
                    id: $0.id ?? "call_\(UUID().uuidString)",
                    name: $0.name,
                    arguments: $0.arguments
                )
            },
            usage: response.usage,
            finishReason: response.finishReason,
            model: response.model
        )
    }
}

private struct PromptToolResponse: Decodable {
    let text: String
    let toolCalls: [PromptToolCall]

    enum CodingKeys: String, CodingKey {
        case text
        case toolCalls
        case tool_calls
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        self.toolCalls = try container.decodeIfPresent([PromptToolCall].self, forKey: .toolCalls)
            ?? container.decodeIfPresent([PromptToolCall].self, forKey: .tool_calls)
            ?? []
    }
}

private struct PromptToolCall: Decodable {
    let id: String?
    let name: String
    let arguments: String

    enum CodingKeys: String, CodingKey {
        case id, name, arguments
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        if let arguments = try? container.decode(String.self, forKey: .arguments) {
            self.arguments = arguments
        } else {
            let object = try container.decode([String: AnyDecodable].self, forKey: .arguments)
            let data = try JSONEncoder().encode(object.mapValues(\.value))
            self.arguments = String(data: data, encoding: .utf8) ?? "{}"
        }
    }
}

private struct AnyDecodable: Decodable {
    let value: AnyEncodable

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.value = AnyEncodable(nil)
        } else if let value = try? container.decode(String.self) {
            self.value = AnyEncodable(value)
        } else if let value = try? container.decode(Int.self) {
            self.value = AnyEncodable(value)
        } else if let value = try? container.decode(Double.self) {
            self.value = AnyEncodable(value)
        } else if let value = try? container.decode(Bool.self) {
            self.value = AnyEncodable(value)
        } else if let value = try? container.decode([String: AnyDecodable].self) {
            self.value = AnyEncodable(value.mapValues(\.value))
        } else if let value = try? container.decode([AnyDecodable].self) {
            self.value = AnyEncodable(value.map(\.value))
        } else {
            throw AIError.invalidResponse
        }
    }
}

private struct AnyEncodable: Encodable {
    let value: Any?

    init(_ value: Any?) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case nil:
            try container.encodeNil()
        case let value as String:
            try container.encode(value)
        case let value as Int:
            try container.encode(value)
        case let value as Double:
            try container.encode(value)
        case let value as Bool:
            try container.encode(value)
        case let value as [String: AnyEncodable]:
            try container.encode(value)
        case let value as [AnyEncodable]:
            try container.encode(value)
        default:
            throw AIError.invalidResponse
        }
    }
}

private func promptToolLoopPrompt(messages: [AIAgentMessage], tools: [AITool]) -> String {
    let toolDescriptions = tools.map { tool in
        let schemaData = try? JSONSerialization.data(withJSONObject: tool.parameters, options: [.sortedKeys])
        let schema = schemaData.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        return """
        - \(tool.name): \(tool.description)
          parameters: \(schema)
        """
    }.joined(separator: "\n")

    let transcript = messages.map { message in
        let content = message.content ?? ""
        if message.role == "tool" {
            return "tool[\(message.toolCallID ?? "")]: \(content)"
        }
        if !message.toolCalls.isEmpty {
            let calls = message.toolCalls.map { "\($0.name)(\($0.arguments))" }.joined(separator: ", ")
            return "\(message.role): \(content)\ntool_calls: \(calls)"
        }
        return "\(message.role): \(content)"
    }.joined(separator: "\n")

    return """
    You can either answer the user or request tools.

    Available tools:
    \(toolDescriptions.isEmpty ? "None" : toolDescriptions)

    Conversation:
    \(transcript)

    Return only valid JSON in this shape:
    {"text":"final answer or empty string","toolCalls":[{"id":"optional id","name":"tool_name","arguments":"{\\"key\\":\\"value\\"}"}]}

    If you need a tool, set text to an empty string and include one or more toolCalls.
    If no tool is needed, put the final answer in text and return an empty toolCalls array.
    """
}

private func decodePromptToolResponse(_ text: String) throws -> PromptToolResponse {
    let cleaned = stripPromptToolMarkdownFences(text)
    guard let data = cleaned.data(using: .utf8) else {
        throw AIError.invalidResponse
    }
    do {
        return try JSONDecoder().decode(PromptToolResponse.self, from: data)
    } catch {
        throw AIError.decodingError(error)
    }
}

private func stripPromptToolMarkdownFences(_ text: String) -> String {
    var value = text.trimmingCharacters(in: .whitespacesAndNewlines)
    if value.hasPrefix("```") {
        let lines = value.components(separatedBy: "\n")
        value = lines.dropFirst().dropLast().joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return value
}
