import Foundation

public enum AgentEvent {
    case agentStarted
    case stepStarted(AgentStepEvent)
    case modelChunk(AIAgentChunk)
    case toolCallStarted(AgentToolCallEvent)
    case toolCallFinished(AgentToolResultEvent)
    case stepFinished(AgentStepEvent)
    case agentFinished(AgentFinishEvent)
    case failed(Error)
}

public struct AgentToolCallEvent: Sendable {
    public let stepIndex: Int
    public let toolCall: AIToolCall

    public init(stepIndex: Int, toolCall: AIToolCall) {
        self.stepIndex = stepIndex
        self.toolCall = toolCall
    }
}

public struct AgentToolResultEvent: Sendable {
    public let stepIndex: Int
    public let toolResult: AIToolResult

    public init(stepIndex: Int, toolResult: AIToolResult) {
        self.stepIndex = stepIndex
        self.toolResult = toolResult
    }
}

public struct AgentStepEvent: Sendable {
    public let stepIndex: Int
    public let step: AIStep?

    public init(stepIndex: Int, step: AIStep? = nil) {
        self.stepIndex = stepIndex
        self.step = step
    }
}

public struct AgentFinishEvent: Sendable {
    public let result: AIStepResult

    public init(result: AIStepResult) {
        self.result = result
    }
}
