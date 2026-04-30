import XCTest
import SwiftyAI

final class MCPPackageTests: XCTestCase {
    func testMCPPublicAPISmoke() async throws {
        let tool = MCPTool(
            name: "echo",
            description: "Echoes input",
            inputSchema: ["type": .string("object")]
        )
        let transport = PackageMockMCPTransport(responses: [
            try packageResponse(id: 1, result: MCPInitializeResult(
                protocolVersion: MCPClient.defaultProtocolVersion,
                capabilities: ["tools": .object([:])],
                serverInfo: MCPImplementation(name: "PackageServer", version: "1.0.0")
            )),
            try packageResponse(id: 2, result: MCPListToolsResult(tools: [tool])),
            try packageResponse(id: 3, result: MCPCallToolResult(
                content: [MCPToolContent(type: "text", fields: ["text": .string("hello")])]
            ))
        ])
        let client = MCPClient(transport: transport)

        try await client.initialize()
        let tools = (try await client.listTools()).asAITools(client: client)
        let output = try await tools[0].execute(["value": "hello"])

        XCTAssertEqual(tools[0].name, "echo")
        XCTAssertEqual(output, "hello")
    }
}

private actor PackageMockMCPTransport: MCPTransport {
    private var responses: [Data?]

    init(responses: [Data?]) {
        self.responses = responses
    }

    func send(_ data: Data, expectsResponse: Bool) async throws -> Data? {
        guard expectsResponse else { return nil }
        guard !responses.isEmpty else {
            throw MCPClientError.invalidResponse("Unexpected MCP package smoke request.")
        }
        return responses.removeFirst()
    }
}

private struct PackageTestResponse<Result: Encodable>: Encodable {
    let jsonrpc = "2.0"
    let id: Int
    let result: Result
}

private func packageResponse<Result: Encodable>(id: Int, result: Result) throws -> Data {
    try JSONEncoder().encode(PackageTestResponse(id: id, result: result))
}
