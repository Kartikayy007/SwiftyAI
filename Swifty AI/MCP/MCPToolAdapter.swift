import Foundation

public extension MCPTool {
    func asAITool(client: MCPClient) -> AITool {
        AITool(
            name: name,
            description: description ?? title ?? name,
            parameters: inputSchema.jsonObject,
            outputSchema: outputSchema?.jsonObject
        ) { arguments in
            let mcpArguments = try arguments.mapValues { try MCPJSONValue(jsonObject: $0) }
            let result = try await client.callTool(name: name, arguments: mcpArguments)
            if result.isError == true {
                throw MCPToolExecutionError(toolName: name, result: result)
            }
            return try result.asAIToolOutput()
        }
    }
}

public extension Sequence where Element == MCPTool {
    func asAITools(client: MCPClient) -> [AITool] {
        map { $0.asAITool(client: client) }
    }
}

public extension MCPCallToolResult {
    func asAIToolOutput() throws -> String {
        let text = textContent
        if !text.isEmpty {
            return text
        }

        if let structuredContent {
            return try encodeJSONObject(structuredContent.jsonObject)
        }

        let data = try JSONEncoder().encode(self)
        return String(data: data, encoding: .utf8) ?? ""
    }
}

private func encodeJSONObject(_ object: Any) throws -> String {
    let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    return String(data: data, encoding: .utf8) ?? ""
}
