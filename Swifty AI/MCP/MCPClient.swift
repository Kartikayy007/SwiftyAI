import Foundation

public actor MCPClient {
    public static let defaultProtocolVersion = "2025-11-25"

    private let transport: any MCPTransport
    private let protocolVersion: String
    private let clientInfo: MCPImplementation
    private let clientCapabilities: [String: MCPJSONValue]
    private var nextRequestID = 1
    private var initializeResult: MCPInitializeResult?

    public init(
        transport: any MCPTransport,
        protocolVersion: String = MCPClient.defaultProtocolVersion,
        clientInfo: MCPImplementation = MCPImplementation(name: "SwiftyAI", version: "1.0.0"),
        capabilities: [String: MCPJSONValue] = [:]
    ) {
        self.transport = transport
        self.protocolVersion = protocolVersion
        self.clientInfo = clientInfo
        self.clientCapabilities = capabilities
    }

    @discardableResult
    public func initialize() async throws -> MCPInitializeResult {
        if let initializeResult {
            return initializeResult
        }

        let params = MCPInitializeParams(
            protocolVersion: protocolVersion,
            capabilities: clientCapabilities,
            clientInfo: clientInfo
        )
        let result: MCPInitializeResult = try await sendRequest(method: "initialize", params: params)
        guard result.protocolVersion == protocolVersion else {
            throw MCPClientError.unsupportedProtocolVersion(
                requested: protocolVersion,
                received: result.protocolVersion
            )
        }

        try await sendNotification(method: "notifications/initialized", params: Optional<MCPJSONValue>.none)
        initializeResult = result
        return result
    }

    public func listTools() async throws -> [MCPTool] {
        try requireInitialized()

        var tools: [MCPTool] = []
        var cursor: String?
        repeat {
            let params = cursor.map { MCPPaginatedRequestParams(cursor: $0) }
            let result: MCPListToolsResult = try await sendRequest(method: "tools/list", params: params)
            tools.append(contentsOf: result.tools)
            cursor = result.nextCursor
        } while cursor != nil

        return tools
    }

    public func callTool(name: String, arguments: [String: MCPJSONValue] = [:]) async throws -> MCPCallToolResult {
        try requireInitialized()
        return try await sendRequest(
            method: "tools/call",
            params: MCPCallToolParams(name: name, arguments: arguments.isEmpty ? nil : arguments)
        )
    }

    private func requireInitialized() throws {
        if initializeResult == nil {
            throw MCPClientError.notInitialized
        }
    }

    private func sendRequest<Params: Encodable & Sendable, Result: Decodable & Sendable>(
        method: String,
        params: Params?
    ) async throws -> Result {
        let id = nextRequestID
        nextRequestID += 1

        let request = MCPJSONRPCRequest(id: .number(id), method: method, params: params)
        let data = try JSONEncoder().encode(request)
        guard let responseData = try await transport.send(data, expectsResponse: true) else {
            throw MCPClientError.missingResponse
        }

        let response = try JSONDecoder().decode(MCPJSONRPCResponse<Result>.self, from: responseData)
        if let error = response.error {
            throw MCPClientError.jsonRPCError(error)
        }
        guard let responseID = response.id else {
            throw MCPClientError.invalidResponse("Response did not contain an id.")
        }
        if responseID != .number(id) {
            throw MCPClientError.invalidResponse("Response id \(responseID) did not match request id \(id).")
        }
        guard let result = response.result else {
            throw MCPClientError.invalidResponse("Response did not contain a result.")
        }
        return result
    }

    private func sendNotification<Params: Encodable & Sendable>(method: String, params: Params?) async throws {
        let notification = MCPJSONRPCNotification(method: method, params: params)
        let data = try JSONEncoder().encode(notification)
        _ = try await transport.send(data, expectsResponse: false)
    }
}
