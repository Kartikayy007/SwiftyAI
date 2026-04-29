import Foundation

public struct AITool {
    public let name: String
    public let description: String
    public let parameters: [String: Any]
    public let execute: ([String: Any]) async throws -> String

    public init(
        name: String,
        description: String,
        parameters: [String: Any],
        execute: @escaping ([String: Any]) async throws -> String
    ) {
        self.name = name
        self.description = description
        self.parameters = parameters
        self.execute = execute
    }
}

public struct AIToolCall: Sendable, Identifiable {
    public let id: String
    public let name: String
    public let arguments: String

    public init(id: String, name: String, arguments: String) {
        self.id = id
        self.name = name
        self.arguments = arguments
    }
}

public struct AIToolResult: Sendable {
    public let toolCallID: String
    public let name: String
    public let content: String
    public let isError: Bool

    public init(toolCallID: String, name: String, content: String, isError: Bool = false) {
        self.toolCallID = toolCallID
        self.name = name
        self.content = content
        self.isError = isError
    }
}

struct AIJSONValue: Encodable {
    let value: Any

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let value as String:
            try container.encode(value)
        case let value as Int:
            try container.encode(value)
        case let value as Double:
            try container.encode(value)
        case let value as Bool:
            try container.encode(value)
        case let value as [String: Any]:
            try container.encode(value.mapValues { AIJSONValue(value: $0) })
        case let value as [Any]:
            try container.encode(value.map { AIJSONValue(value: $0) })
        case _ as NSNull:
            try container.encodeNil()
        default:
            throw EncodingError.invalidValue(
                value,
                .init(codingPath: encoder.codingPath, debugDescription: "Unsupported JSON schema value")
            )
        }
    }
}
