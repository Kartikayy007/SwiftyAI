import Foundation
@testable import Swifty_AI

/// Builds a fake `text/event-stream` HTTP response from an array of JSON-serializable chunk dicts.
func mockSSEResponse(chunks: [[String: Any]]) throws -> (HTTPURLResponse, Data) {
    var body = ""
    for chunk in chunks {
        let data = try JSONSerialization.data(withJSONObject: chunk)
        let json = String(data: data, encoding: .utf8)!
        body += "data: \(json)\n\n"
    }
    body += "data: [DONE]\n\n"

    let responseData = body.data(using: .utf8)!
    let response = HTTPURLResponse(
        url: URL(string: "https://mock")!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["Content-Type": "text/event-stream"]
    )!
    return (response, responseData)
}

/// Builds a fake Anthropic SSE response with text deltas and a final message_delta.
func mockAnthropicSSEResponse(
    textDeltas: [String],
    stopReason: String,
    inputTokens: Int = 10,
    outputTokens: Int = 5
) throws -> (HTTPURLResponse, Data) {
    var events: [String] = []

    // message_start with usage
    let messageStart = """
    {"type":"message_start","message":{"usage":{"input_tokens":\(inputTokens)}}}
    """
    events.append("data: \(messageStart)")

    // content_block_start
    events.append(#"data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}"#)

    // text deltas
    for delta in textDeltas {
        let escaped = delta.replacingOccurrences(of: "\"", with: "\\\"")
        events.append(#"data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"\#(escaped)"}}"#)
    }

    // content_block_stop
    events.append(#"data: {"type":"content_block_stop","index":0}"#)

    // message_delta with stop reason and output tokens
    let msgDelta = """
    {"type":"message_delta","delta":{"stop_reason":"\(stopReason)"},"usage":{"output_tokens":\(outputTokens)}}
    """
    events.append("data: \(msgDelta)")

    // message_stop
    events.append(#"data: {"type":"message_stop"}"#)

    let body = events.joined(separator: "\n\n") + "\n\n"
    let responseData = body.data(using: .utf8)!
    let response = HTTPURLResponse(
        url: URL(string: "https://mock")!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["Content-Type": "text/event-stream"]
    )!
    return (response, responseData)
}
