import Foundation

public struct ContextWindow: Sendable {
    public let maxTokens: Int
    public let warningThreshold: Double

    public init(maxTokens: Int, warningThreshold: Double = 0.9) {
        self.maxTokens = max(0, maxTokens)
        self.warningThreshold = min(max(warningThreshold, 0), 1)
    }

    public func estimatedTokens(for text: String) -> Int {
        guard !text.isEmpty else { return 0 }
        return max(1, (text.count + 3) / 4)
    }

    public func estimatedTokens(for messages: [ChatMessage]) -> Int {
        messages.reduce(0) { partialResult, message in
            partialResult + estimatedTokens(for: message)
        }
    }

    public func remaining(for messages: [ChatMessage]) -> Int {
        max(0, maxTokens - estimatedTokens(for: messages))
    }

    public func isNearLimit(for messages: [ChatMessage]) -> Bool {
        let threshold = Int((Double(maxTokens) * warningThreshold).rounded(.up))
        return estimatedTokens(for: messages) >= threshold
    }

    private func estimatedTokens(for message: ChatMessage) -> Int {
        estimatedTokens(for: message.role.rawValue) + estimatedTokens(for: message.parts)
    }

    private func estimatedTokens(for parts: [AIMessageContent]) -> Int {
        parts.reduce(0) { partialResult, part in
            partialResult + estimatedTokens(for: part)
        }
    }

    private func estimatedTokens(for part: AIMessageContent) -> Int {
        switch part {
        case .text(let text):
            return estimatedTokens(for: text)
        default:
            return 256
        }
    }
}
