import Foundation

public struct AITool {
    public let name: String
    public let description: String
    public let parameters: [String: Any]
    public let outputSchema: [String: Any]?
    public let execute: ([String: Any]) async throws -> String

    public init(
        name: String,
        description: String,
        parameters: [String: Any],
        outputSchema: [String: Any]? = nil,
        execute: @escaping ([String: Any]) async throws -> String
    ) {
        self.name = name
        self.description = description
        self.parameters = parameters
        self.outputSchema = outputSchema
        self.execute = execute
    }
}

public func tool<Input: Decodable, OutputValue: Encodable>(
    name: String,
    description: String,
    inputSchema: AISchema,
    outputSchema: AISchema? = nil,
    execute: @escaping (Input) async throws -> OutputValue
) -> AITool {
    AITool(
        name: name,
        description: description,
        parameters: inputSchema.jsonSchema,
        outputSchema: outputSchema?.jsonSchema
    ) { arguments in
        let data = try JSONSerialization.data(withJSONObject: arguments)
        let input = try JSONDecoder().decode(Input.self, from: data)
        let output = try await execute(input)
        return try encodeToolOutput(output)
    }
}

public func dynamicTool(
    name: String,
    description: String,
    inputSchema: AISchema,
    outputSchema: AISchema? = nil,
    execute: @escaping ([String: Any]) async throws -> String
) -> AITool {
    AITool(
        name: name,
        description: description,
        parameters: inputSchema.jsonSchema,
        outputSchema: outputSchema?.jsonSchema,
        execute: execute
    )
}

private func encodeToolOutput<OutputValue: Encodable>(_ output: OutputValue) throws -> String {
    if let string = output as? String {
        return string
    }
    let data = try JSONEncoder().encode(output)
    return String(data: data, encoding: .utf8) ?? ""
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

public enum ToolCallDecision: Sendable {
    case execute
    case reject(reason: String)
    case returnResult(String)
    case replaceArguments(String)
}

public enum ToolErrorPolicy: Sendable, Equatable {
    case returnErrorResult
    case failFast
}

public struct ToolExecutionOptions {
    public var approval: ((AIToolCall) -> ToolCallDecision)?
    public var onToolCall: ((AIToolCall) -> ToolCallDecision)?
    public var onToolResult: ((AIToolResult) -> Void)?
    public var parallelToolCalls: Bool
    public var errorPolicy: ToolErrorPolicy

    public init(
        approval: ((AIToolCall) -> ToolCallDecision)? = nil,
        onToolCall: ((AIToolCall) -> ToolCallDecision)? = nil,
        onToolResult: ((AIToolResult) -> Void)? = nil,
        parallelToolCalls: Bool = false,
        errorPolicy: ToolErrorPolicy = .returnErrorResult
    ) {
        self.approval = approval
        self.onToolCall = onToolCall
        self.onToolResult = onToolResult
        self.parallelToolCalls = parallelToolCalls
        self.errorPolicy = errorPolicy
    }

    public static let `default` = ToolExecutionOptions()
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
