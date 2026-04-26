public struct TokenUsage: Sendable {
    public let inputTokens: Int
    public let outputTokens: Int
}

public struct AIResponse: Sendable {
    public let text: String
    public let model: String?
    public let usage: TokenUsage?
    public let finishReason: String?
}
