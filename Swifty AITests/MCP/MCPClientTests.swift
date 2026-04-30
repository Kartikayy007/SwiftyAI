import XCTest
@testable import Swifty_AI

final class MCPClientTests: XCTestCase {
    func testInitializeSendsHandshakeAndInitializedNotification() async throws {
        let transport = MockMCPTransport(responses: [
            try response(id: 1, result: initializeResult())
        ])
        let client = MCPClient(transport: transport)

        let result = try await client.initialize()

        XCTAssertEqual(result.protocolVersion, MCPClient.defaultProtocolVersion)
        let sent = await transport.sentMessages()
        XCTAssertEqual(sent.count, 2)
        XCTAssertTrue(sent[0].expectsResponse)
        XCTAssertFalse(sent[1].expectsResponse)

        let initialize = try jsonObject(sent[0].data)
        XCTAssertEqual(initialize["method"] as? String, "initialize")
        let params = initialize["params"] as? [String: Any]
        XCTAssertEqual(params?["protocolVersion"] as? String, MCPClient.defaultProtocolVersion)
        let clientInfo = params?["clientInfo"] as? [String: Any]
        XCTAssertEqual(clientInfo?["name"] as? String, "SwiftyAI")

        let initialized = try jsonObject(sent[1].data)
        XCTAssertEqual(initialized["method"] as? String, "notifications/initialized")
        XCTAssertNil(initialized["id"])
    }

    func testListToolsFetchesAllPages() async throws {
        let firstTool = MCPTool(
            name: "weather",
            description: "Gets weather",
            inputSchema: objectSchema(properties: ["city": objectSchema(type: "string")])
        )
        let secondTool = MCPTool(
            name: "time",
            description: "Gets time",
            inputSchema: objectSchema()
        )
        let transport = MockMCPTransport(responses: [
            try response(id: 1, result: initializeResult()),
            try response(id: 2, result: MCPListToolsResult(tools: [firstTool], nextCursor: "next")),
            try response(id: 3, result: MCPListToolsResult(tools: [secondTool]))
        ])
        let client = MCPClient(transport: transport)

        try await client.initialize()
        let tools = try await client.listTools()

        XCTAssertEqual(tools.map(\.name), ["weather", "time"])
        let sent = await transport.sentMessages()
        XCTAssertEqual(try jsonObject(sent[2].data)["method"] as? String, "tools/list")
        let secondList = try jsonObject(sent[3].data)
        let params = secondList["params"] as? [String: Any]
        XCTAssertEqual(params?["cursor"] as? String, "next")
    }

    func testCallToolSendsArgumentsAndDecodesResult() async throws {
        let transport = MockMCPTransport(responses: [
            try response(id: 1, result: initializeResult()),
            try response(id: 2, result: MCPCallToolResult(
                content: [MCPToolContent(type: "text", fields: ["text": .string("Sunny")])],
                structuredContent: ["temperature": .number(29)]
            ))
        ])
        let client = MCPClient(transport: transport)

        try await client.initialize()
        let result = try await client.callTool(name: "weather", arguments: ["city": .string("Delhi")])

        XCTAssertEqual(result.textContent, "Sunny")
        XCTAssertEqual(result.structuredContent?["temperature"], .number(29))

        let sent = await transport.sentMessages()
        let call = try jsonObject(sent[2].data)
        XCTAssertEqual(call["method"] as? String, "tools/call")
        let params = call["params"] as? [String: Any]
        XCTAssertEqual(params?["name"] as? String, "weather")
        let arguments = params?["arguments"] as? [String: Any]
        XCTAssertEqual(arguments?["city"] as? String, "Delhi")
    }

    func testJSONRPCErrorIsSurfaced() async throws {
        let transport = MockMCPTransport(responses: [
            try response(id: 1, result: initializeResult()),
            try errorResponse(id: 2, error: MCPJSONRPCError(code: -32601, message: "No tools"))
        ])
        let client = MCPClient(transport: transport)

        try await client.initialize()

        do {
            _ = try await client.listTools()
            XCTFail("Expected JSON-RPC error")
        } catch MCPClientError.jsonRPCError(let error) {
            XCTAssertEqual(error.code, -32601)
            XCTAssertEqual(error.message, "No tools")
        }
    }

    func testOperationalRequestsRequireInitialization() async throws {
        let client = MCPClient(transport: MockMCPTransport(responses: []))

        do {
            _ = try await client.listTools()
            XCTFail("Expected notInitialized")
        } catch MCPClientError.notInitialized {
            // Expected.
        }
    }

    func testInitializeRejectsUnsupportedNegotiatedProtocolVersion() async throws {
        let transport = MockMCPTransport(responses: [
            try response(id: 1, result: initializeResult(protocolVersion: "2024-11-05"))
        ])
        let client = MCPClient(transport: transport)

        do {
            _ = try await client.initialize()
            XCTFail("Expected unsupported protocol version")
        } catch MCPClientError.unsupportedProtocolVersion(let requested, let received) {
            XCTAssertEqual(requested, MCPClient.defaultProtocolVersion)
            XCTAssertEqual(received, "2024-11-05")
        }

        let sent = await transport.sentMessages()
        XCTAssertEqual(sent.count, 1)
    }

    func testDiscoveredToolsAdaptToExecutableAITools() async throws {
        let mcpTool = MCPTool(
            name: "weather",
            title: "Weather",
            description: "Gets weather",
            inputSchema: objectSchema(properties: ["city": objectSchema(type: "string")]),
            outputSchema: objectSchema(properties: ["forecast": objectSchema(type: "string")])
        )
        let transport = MockMCPTransport(responses: [
            try response(id: 1, result: initializeResult()),
            try response(id: 2, result: MCPListToolsResult(tools: [mcpTool])),
            try response(id: 3, result: MCPCallToolResult(
                content: [MCPToolContent(type: "text", fields: ["text": .string("Sunny in Delhi")])]
            ))
        ])
        let client = MCPClient(transport: transport)

        try await client.initialize()
        let tools = (try await client.listTools()).asAITools(client: client)
        let output = try await tools[0].execute(["city": "Delhi"])

        XCTAssertEqual(tools[0].name, "weather")
        XCTAssertEqual(tools[0].description, "Gets weather")
        XCTAssertNotNil(tools[0].outputSchema)
        XCTAssertEqual(output, "Sunny in Delhi")

        let sent = await transport.sentMessages()
        let call = try jsonObject(sent[3].data)
        let params = call["params"] as? [String: Any]
        let arguments = params?["arguments"] as? [String: Any]
        XCTAssertEqual(arguments?["city"] as? String, "Delhi")
    }

    func testAdapterThrowsToolExecutionErrors() async throws {
        let mcpTool = MCPTool(name: "validate", inputSchema: objectSchema())
        let transport = MockMCPTransport(responses: [
            try response(id: 1, result: initializeResult()),
            try response(id: 2, result: MCPCallToolResult(
                content: [MCPToolContent(type: "text", fields: ["text": .string("Invalid input")])],
                isError: true
            ))
        ])
        let client = MCPClient(transport: transport)
        let tool = mcpTool.asAITool(client: client)

        try await client.initialize()

        do {
            _ = try await tool.execute([:])
            XCTFail("Expected tool execution error")
        } catch let error as MCPToolExecutionError {
            XCTAssertEqual(error.toolName, "validate")
            XCTAssertEqual(error.localizedDescription, "Invalid input")
        }
    }
}

private actor MockMCPTransport: MCPTransport {
    private var responses: [Data?]
    private var sent: [RecordedMessage] = []

    init(responses: [Data?]) {
        self.responses = responses
    }

    func send(_ data: Data, expectsResponse: Bool) async throws -> Data? {
        sent.append(RecordedMessage(data: data, expectsResponse: expectsResponse))
        guard expectsResponse else { return nil }
        guard !responses.isEmpty else {
            throw MCPClientError.invalidResponse("Unexpected MCP request.")
        }
        return responses.removeFirst()
    }

    func sentMessages() -> [RecordedMessage] {
        sent
    }
}

private struct RecordedMessage: Sendable {
    let data: Data
    let expectsResponse: Bool
}

private struct TestResponse<Result: Encodable>: Encodable {
    let jsonrpc = "2.0"
    let id: Int
    let result: Result
}

private struct TestErrorResponse: Encodable {
    let jsonrpc = "2.0"
    let id: Int
    let error: MCPJSONRPCError
}

private func response<Result: Encodable>(id: Int, result: Result) throws -> Data {
    try JSONEncoder().encode(TestResponse(id: id, result: result))
}

private func errorResponse(id: Int, error: MCPJSONRPCError) throws -> Data {
    try JSONEncoder().encode(TestErrorResponse(id: id, error: error))
}

private func initializeResult(protocolVersion: String = MCPClient.defaultProtocolVersion) -> MCPInitializeResult {
    MCPInitializeResult(
        protocolVersion: protocolVersion,
        capabilities: ["tools": .object(["listChanged": .bool(true)])],
        serverInfo: MCPImplementation(name: "TestServer", version: "1.0.0")
    )
}

private func objectSchema(
    type: String = "object",
    properties: [String: [String: MCPJSONValue]] = [:]
) -> [String: MCPJSONValue] {
    var schema: [String: MCPJSONValue] = ["type": .string(type)]
    if !properties.isEmpty {
        schema["properties"] = .object(properties.mapValues { .object($0) })
    }
    return schema
}

private func jsonObject(_ data: Data) throws -> [String: Any] {
    try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
}
