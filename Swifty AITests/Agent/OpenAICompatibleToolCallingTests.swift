import Foundation
import XCTest
@testable import Swifty_AI

final class OpenAICompatibleToolCallingTests: XCTestCase {
    func testGenerateStepSendsOpenAIToolRequest() async throws {
        var capturedBody: [String: Any] = [:]
        MockURLProtocol.handler = { request in
            let body = try XCTUnwrap(request.httpBody)
            capturedBody = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
            return try mockResponse(statusCode: 200, json: [
                "id": "chatcmpl-test",
                "object": "chat.completion",
                "model": "gpt-4o-mini",
                "choices": [[
                    "index": 0,
                    "message": [
                        "role": "assistant",
                        "content": NSNull(),
                        "tool_calls": [[
                            "id": "call_1",
                            "type": "function",
                            "function": [
                                "name": "weather",
                                "arguments": #"{"city":"Delhi"}"#
                            ]
                        ]]
                    ],
                    "finish_reason": "tool_calls"
                ]],
                "usage": [
                    "prompt_tokens": 10,
                    "completion_tokens": 5,
                    "total_tokens": 15,
                    "prompt_tokens_details": ["cached_tokens": 4]
                ]
            ])
        }

        let provider = OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: "sk-test", model: "gpt-4o-mini", session: .mock)
        let response = try await provider.generateStep(
            messages: [.init(role: "user", content: "weather?")],
            tools: [
                AITool(
                    name: "weather",
                    description: "Gets weather",
                    parameters: [
                        "type": "object",
                        "properties": ["city": ["type": "string"]],
                        "required": ["city"]
                    ],
                    execute: { _ in "" }
                )
            ],
            options: GenerationOptions(headers: ["X-Test": "1"], promptCaching: .init(cacheKey: "user-1", retention: "24h"))
        )

        XCTAssertEqual(response.toolCalls.first?.name, "weather")
        XCTAssertEqual(response.usage?.cachedInputTokens, 4)
        XCTAssertEqual(capturedBody["tool_choice"] as? String, "auto")
        XCTAssertEqual(capturedBody["prompt_cache_key"] as? String, "user-1")
        XCTAssertEqual(capturedBody["prompt_cache_retention"] as? String, "24h")

        let tools = try XCTUnwrap(capturedBody["tools"] as? [[String: Any]])
        XCTAssertEqual(tools.first?["type"] as? String, "function")
    }
}

