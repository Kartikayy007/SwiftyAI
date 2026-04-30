import Foundation

public enum MCPJSONValue: Codable, Equatable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: MCPJSONValue])
    case array([MCPJSONValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([MCPJSONValue].self) {
            self = .array(value)
        } else {
            self = .object(try container.decode([String: MCPJSONValue].self))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }

    public init(jsonObject value: Any) throws {
        switch value {
        case let value as MCPJSONValue:
            self = value
        case let value as String:
            self = .string(value)
        case let value as Bool:
            self = .bool(value)
        case let value as Int:
            self = .number(Double(value))
        case let value as Int8:
            self = .number(Double(value))
        case let value as Int16:
            self = .number(Double(value))
        case let value as Int32:
            self = .number(Double(value))
        case let value as Int64:
            self = .number(Double(value))
        case let value as UInt:
            self = .number(Double(value))
        case let value as UInt8:
            self = .number(Double(value))
        case let value as UInt16:
            self = .number(Double(value))
        case let value as UInt32:
            self = .number(Double(value))
        case let value as UInt64:
            self = .number(Double(value))
        case let value as Float:
            self = .number(Double(value))
        case let value as Double:
            self = .number(value)
        case let value as Decimal:
            self = .number(NSDecimalNumber(decimal: value).doubleValue)
        case let value as [String: Any]:
            var object: [String: MCPJSONValue] = [:]
            for (key, child) in value {
                object[key] = try MCPJSONValue(jsonObject: child)
            }
            self = .object(object)
        case let value as [Any]:
            self = .array(try value.map { try MCPJSONValue(jsonObject: $0) })
        case _ as NSNull:
            self = .null
        default:
            throw MCPClientError.invalidJSONValue("Unsupported JSON value: \(type(of: value))")
        }
    }

    public var jsonObject: Any {
        switch self {
        case .string(let value):
            return value
        case .number(let value):
            return value
        case .bool(let value):
            return value
        case .object(let value):
            return value.mapValues(\.jsonObject)
        case .array(let value):
            return value.map(\.jsonObject)
        case .null:
            return NSNull()
        }
    }

    public var stringValue: String? {
        guard case .string(let value) = self else { return nil }
        return value
    }
}

public enum MCPJSONRPCID: Codable, Equatable, Sendable {
    case number(Int)
    case string(String)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Int.self) {
            self = .number(value)
        } else {
            self = .string(try container.decode(String.self))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .number(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        }
    }
}

public struct MCPJSONRPCRequest<Params: Encodable & Sendable>: Encodable, Sendable {
    public let jsonrpc: String
    public let id: MCPJSONRPCID
    public let method: String
    public let params: Params?

    public init(id: MCPJSONRPCID, method: String, params: Params? = nil) {
        self.jsonrpc = "2.0"
        self.id = id
        self.method = method
        self.params = params
    }
}

public struct MCPJSONRPCNotification<Params: Encodable & Sendable>: Encodable, Sendable {
    public let jsonrpc: String
    public let method: String
    public let params: Params?

    public init(method: String, params: Params? = nil) {
        self.jsonrpc = "2.0"
        self.method = method
        self.params = params
    }
}

public struct MCPJSONRPCResponse<Result: Decodable & Sendable>: Decodable, Sendable {
    public let jsonrpc: String
    public let id: MCPJSONRPCID?
    public let result: Result?
    public let error: MCPJSONRPCError?

    public init(
        jsonrpc: String = "2.0",
        id: MCPJSONRPCID?,
        result: Result? = nil,
        error: MCPJSONRPCError? = nil
    ) {
        self.jsonrpc = jsonrpc
        self.id = id
        self.result = result
        self.error = error
    }
}

public struct MCPJSONRPCError: Codable, Equatable, Error, Sendable {
    public let code: Int
    public let message: String
    public let data: MCPJSONValue?

    public init(code: Int, message: String, data: MCPJSONValue? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }
}

extension MCPJSONRPCError: LocalizedError {
    public var errorDescription: String? {
        "MCP JSON-RPC error \(code): \(message)"
    }
}

public enum MCPClientError: Error, Equatable, Sendable {
    case notInitialized
    case missingResponse
    case invalidResponse(String)
    case jsonRPCError(MCPJSONRPCError)
    case unsupportedProtocolVersion(requested: String, received: String)
    case invalidJSONValue(String)
}

extension MCPClientError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "MCP client must be initialized before sending operational requests."
        case .missingResponse:
            return "MCP transport did not return a response."
        case .invalidResponse(let message):
            return "Invalid MCP response: \(message)"
        case .jsonRPCError(let error):
            return error.localizedDescription
        case .unsupportedProtocolVersion(let requested, let received):
            return "Unsupported MCP protocol version. Requested \(requested), received \(received)."
        case .invalidJSONValue(let message):
            return message
        }
    }
}

public struct MCPToolExecutionError: Error, Equatable, Sendable {
    public let toolName: String
    public let result: MCPCallToolResult

    public init(toolName: String, result: MCPCallToolResult) {
        self.toolName = toolName
        self.result = result
    }
}

extension MCPToolExecutionError: LocalizedError {
    public var errorDescription: String? {
        let text = result.textContent
        return text.isEmpty ? "MCP tool \(toolName) returned an error." : text
    }
}

public struct MCPImplementation: Codable, Equatable, Sendable {
    public let name: String
    public let title: String?
    public let version: String
    public let description: String?
    public let icons: [MCPIcon]?
    public let websiteUrl: String?

    public init(
        name: String,
        title: String? = nil,
        version: String,
        description: String? = nil,
        icons: [MCPIcon]? = nil,
        websiteUrl: String? = nil
    ) {
        self.name = name
        self.title = title
        self.version = version
        self.description = description
        self.icons = icons
        self.websiteUrl = websiteUrl
    }
}

public struct MCPIcon: Codable, Equatable, Sendable {
    public let src: String
    public let mimeType: String?
    public let sizes: [String]?

    public init(src: String, mimeType: String? = nil, sizes: [String]? = nil) {
        self.src = src
        self.mimeType = mimeType
        self.sizes = sizes
    }
}

public struct MCPInitializeParams: Codable, Equatable, Sendable {
    public let protocolVersion: String
    public let capabilities: [String: MCPJSONValue]
    public let clientInfo: MCPImplementation

    public init(
        protocolVersion: String,
        capabilities: [String: MCPJSONValue] = [:],
        clientInfo: MCPImplementation
    ) {
        self.protocolVersion = protocolVersion
        self.capabilities = capabilities
        self.clientInfo = clientInfo
    }
}

public struct MCPInitializeResult: Codable, Equatable, Sendable {
    public let protocolVersion: String
    public let capabilities: [String: MCPJSONValue]
    public let serverInfo: MCPImplementation
    public let instructions: String?

    public init(
        protocolVersion: String,
        capabilities: [String: MCPJSONValue],
        serverInfo: MCPImplementation,
        instructions: String? = nil
    ) {
        self.protocolVersion = protocolVersion
        self.capabilities = capabilities
        self.serverInfo = serverInfo
        self.instructions = instructions
    }
}

public struct MCPPaginatedRequestParams: Codable, Equatable, Sendable {
    public let cursor: String?

    public init(cursor: String? = nil) {
        self.cursor = cursor
    }
}

public struct MCPListToolsResult: Codable, Equatable, Sendable {
    public let tools: [MCPTool]
    public let nextCursor: String?
    public let meta: [String: MCPJSONValue]?

    public init(tools: [MCPTool], nextCursor: String? = nil, meta: [String: MCPJSONValue]? = nil) {
        self.tools = tools
        self.nextCursor = nextCursor
        self.meta = meta
    }

    private enum CodingKeys: String, CodingKey {
        case tools
        case nextCursor
        case meta = "_meta"
    }
}

public struct MCPTool: Codable, Equatable, Sendable {
    public let name: String
    public let title: String?
    public let description: String?
    public let inputSchema: [String: MCPJSONValue]
    public let outputSchema: [String: MCPJSONValue]?
    public let annotations: [String: MCPJSONValue]?
    public let execution: [String: MCPJSONValue]?
    public let icons: [MCPIcon]?
    public let meta: [String: MCPJSONValue]?

    public init(
        name: String,
        title: String? = nil,
        description: String? = nil,
        inputSchema: [String: MCPJSONValue],
        outputSchema: [String: MCPJSONValue]? = nil,
        annotations: [String: MCPJSONValue]? = nil,
        execution: [String: MCPJSONValue]? = nil,
        icons: [MCPIcon]? = nil,
        meta: [String: MCPJSONValue]? = nil
    ) {
        self.name = name
        self.title = title
        self.description = description
        self.inputSchema = inputSchema
        self.outputSchema = outputSchema
        self.annotations = annotations
        self.execution = execution
        self.icons = icons
        self.meta = meta
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case title
        case description
        case inputSchema
        case outputSchema
        case annotations
        case execution
        case icons
        case meta = "_meta"
    }
}

public struct MCPCallToolParams: Codable, Equatable, Sendable {
    public let name: String
    public let arguments: [String: MCPJSONValue]?

    public init(name: String, arguments: [String: MCPJSONValue]? = nil) {
        self.name = name
        self.arguments = arguments
    }
}

public struct MCPCallToolResult: Codable, Equatable, Sendable {
    public let content: [MCPToolContent]
    public let structuredContent: [String: MCPJSONValue]?
    public let isError: Bool?
    public let meta: [String: MCPJSONValue]?

    public init(
        content: [MCPToolContent],
        structuredContent: [String: MCPJSONValue]? = nil,
        isError: Bool? = nil,
        meta: [String: MCPJSONValue]? = nil
    ) {
        self.content = content
        self.structuredContent = structuredContent
        self.isError = isError
        self.meta = meta
    }

    public var textContent: String {
        content.compactMap(\.text).joined(separator: "\n")
    }

    private enum CodingKeys: String, CodingKey {
        case content
        case structuredContent
        case isError
        case meta = "_meta"
    }
}

public struct MCPToolContent: Codable, Equatable, Sendable {
    public let type: String
    public let fields: [String: MCPJSONValue]

    public init(type: String, fields: [String: MCPJSONValue] = [:]) {
        var fields = fields
        fields["type"] = .string(type)
        self.type = type
        self.fields = fields
    }

    public var text: String? {
        fields["text"]?.stringValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let fields = try container.decode([String: MCPJSONValue].self)
        guard let type = fields["type"]?.stringValue else {
            throw MCPClientError.invalidResponse("Tool content is missing a string type.")
        }
        self.type = type
        self.fields = fields
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(fields)
    }
}

extension Dictionary where Key == String, Value == MCPJSONValue {
    public var jsonObject: [String: Any] {
        mapValues(\.jsonObject)
    }
}
