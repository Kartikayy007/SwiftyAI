import Foundation

public struct AIAgentMessage: Sendable {
    public let role: String
    public let content: String?
    public let toolCalls: [AIToolCall]
    public let toolCallID: String?
    public let name: String?

    public init(
        role: String,
        content: String? = nil,
        toolCalls: [AIToolCall] = [],
        toolCallID: String? = nil,
        name: String? = nil
    ) {
        self.role = role
        self.content = content
        self.toolCalls = toolCalls
        self.toolCallID = toolCallID
        self.name = name
    }
}

public struct AIToolStepResponse: Sendable {
    public let text: String
    public let toolCalls: [AIToolCall]
    public let usage: TokenUsage?
    public let finishReason: String?
    public let model: String?

    public init(
        text: String,
        toolCalls: [AIToolCall] = [],
        usage: TokenUsage? = nil,
        finishReason: String? = nil,
        model: String? = nil
    ) {
        self.text = text
        self.toolCalls = toolCalls
        self.usage = usage
        self.finishReason = finishReason
        self.model = model
    }
}

public struct AIStep: Sendable {
    public let index: Int
    public let text: String
    public let toolCalls: [AIToolCall]
    public let toolResults: [AIToolResult]
    public let usage: TokenUsage?
    public let finishReason: String?

    public init(
        index: Int,
        text: String,
        toolCalls: [AIToolCall] = [],
        toolResults: [AIToolResult] = [],
        usage: TokenUsage? = nil,
        finishReason: String? = nil
    ) {
        self.index = index
        self.text = text
        self.toolCalls = toolCalls
        self.toolResults = toolResults
        self.usage = usage
        self.finishReason = finishReason
    }
}

public struct AIStepResult: Sendable {
    public let text: String
    public let steps: [AIStep]
    public let usage: TokenUsage?
    public let finishReason: String?
    public let isMaxStepsExceeded: Bool

    public init(
        text: String,
        steps: [AIStep],
        usage: TokenUsage?,
        finishReason: String?,
        isMaxStepsExceeded: Bool = false
    ) {
        self.text = text
        self.steps = steps
        self.usage = usage
        self.finishReason = finishReason
        self.isMaxStepsExceeded = isMaxStepsExceeded
    }
}

public struct AIAgentChunk: Sendable {
    public let text: String
    public let stepIndex: Int
    public let toolCall: AIToolCall?
    public let toolResult: AIToolResult?
    public let usage: TokenUsage?
    public let finishReason: String?

    public init(
        text: String = "",
        stepIndex: Int,
        toolCall: AIToolCall? = nil,
        toolResult: AIToolResult? = nil,
        usage: TokenUsage? = nil,
        finishReason: String? = nil
    ) {
        self.text = text
        self.stepIndex = stepIndex
        self.toolCall = toolCall
        self.toolResult = toolResult
        self.usage = usage
        self.finishReason = finishReason
    }
}

