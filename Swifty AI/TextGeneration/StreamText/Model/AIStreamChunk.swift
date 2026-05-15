public struct AIStreamChunk: Sendable {
    public let text: String
    public let finishReason: String?
    public let usage: TokenUsage?

    public init(text: String, finishReason: String? = nil, usage: TokenUsage? = nil) {
        self.text = text
        self.finishReason = finishReason
        self.usage = usage
    }
}
