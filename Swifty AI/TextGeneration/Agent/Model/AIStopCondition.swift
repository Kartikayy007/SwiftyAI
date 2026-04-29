public struct AIStopContext: Sendable {
    public let step: AIStep
    public let maxSteps: Int

    public init(step: AIStep, maxSteps: Int) {
        self.step = step
        self.maxSteps = maxSteps
    }
}

public struct AIStopCondition {
    public let name: String
    private let predicate: (AIStopContext) -> Bool

    public init(name: String, _ predicate: @escaping (AIStopContext) -> Bool) {
        self.name = name
        self.predicate = predicate
    }

    public func evaluate(_ context: AIStopContext) -> Bool {
        predicate(context)
    }
}

public func stepCountIs(_ count: Int) -> AIStopCondition {
    AIStopCondition(name: "stepCountIs") { context in
        context.step.index == count
    }
}

public func hasToolCall(_ name: String? = nil) -> AIStopCondition {
    AIStopCondition(name: "hasToolCall") { context in
        guard let name else {
            return !context.step.toolCalls.isEmpty
        }
        return context.step.toolCalls.contains { $0.name == name }
    }
}

public func isLoopFinished() -> AIStopCondition {
    AIStopCondition(name: "isLoopFinished") { context in
        context.step.toolCalls.isEmpty
    }
}

