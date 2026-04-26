public struct AIStreamChunk: Sendable {
    public let text: String
    public let finishReason: String?
    public let usage: TokenUsage?
}
