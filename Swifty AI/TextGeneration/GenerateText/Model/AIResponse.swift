public struct TokenUsage: Sendable {
    public let inputTokens: Int
    public let outputTokens: Int
    public let totalTokens: Int?
    public let cachedInputTokens: Int?

    public init(
        inputTokens: Int,
        outputTokens: Int,
        totalTokens: Int? = nil,
        cachedInputTokens: Int? = nil
    ) {
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.totalTokens = totalTokens
        self.cachedInputTokens = cachedInputTokens
    }
}

public struct AIResponse: Sendable {
    public let text: String
    public let model: String?
    public let usage: TokenUsage?
    public let finishReason: String?

    public init(text: String, model: String? = nil, usage: TokenUsage? = nil, finishReason: String? = nil) {
        self.text = text
        self.model = model
        self.usage = usage
        self.finishReason = finishReason
    }
}
