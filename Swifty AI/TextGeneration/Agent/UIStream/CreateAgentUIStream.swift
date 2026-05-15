import Foundation

public func createAgentUIStream(
    model: some AIToolCallingModel,
    prompt: String,
    tools: [AITool],
    options: GenerationOptions = GenerationOptions(),
    maxSteps: Int = 5,
    stopWhen: [AIStopCondition] = [isLoopFinished()],
    onEvent: ((AgentEvent) -> Void)? = nil,
    onStepFinish: ((AIStep) -> Void)? = nil,
    onFinish: ((AIStepResult) -> Void)? = nil,
    toolOptions: ToolExecutionOptions = .default
) -> AsyncThrowingStream<AgentEvent, Error> {
    AsyncThrowingStream { continuation in
        Task {
            let emit: (AgentEvent) -> Void = { event in
                onEvent?(event)
                continuation.yield(event)
            }

            do {
                emit(.agentStarted)

                var messages = initialAgentMessages(prompt: prompt, options: options)
                let result = try await runToolLoop(
                    model: model,
                    messages: &messages,
                    tools: tools,
                    options: options,
                    maxSteps: maxSteps,
                    stopWhen: stopWhen,
                    onStepFinish: onStepFinish,
                    toolOptions: toolOptions,
                    onAgentEvent: emit,
                    onEvent: nil
                )

                let finishEvent = AgentEvent.agentFinished(AgentFinishEvent(result: result))
                emit(finishEvent)
                onFinish?(result)
                continuation.finish()
            } catch {
                let failureEvent = AgentEvent.failed(error)
                emit(failureEvent)
                continuation.finish(throwing: error)
            }
        }
    }
}

public func createAgentUIStream(
    model: String,
    prompt: String,
    tools: [AITool],
    options: GenerationOptions = GenerationOptions(),
    maxSteps: Int = 5,
    stopWhen: [AIStopCondition] = [isLoopFinished()],
    onEvent: ((AgentEvent) -> Void)? = nil,
    onStepFinish: ((AIStep) -> Void)? = nil,
    onFinish: ((AIStepResult) -> Void)? = nil,
    toolOptions: ToolExecutionOptions = .default
) -> AsyncThrowingStream<AgentEvent, Error> {
    AsyncThrowingStream { continuation in
        Task {
            let emit: (AgentEvent) -> Void = { event in
                onEvent?(event)
                continuation.yield(event)
            }

            do {
                emit(.agentStarted)

                let resolved = try await AIRegistry.shared.resolve(model)
                guard let toolModel = resolved as? any AIToolCallingModel else {
                    throw AIError.unsupportedFeature("Tool calling is not implemented by this provider")
                }

                var messages = initialAgentMessages(prompt: prompt, options: options)
                let result = try await runToolLoop(
                    model: toolModel,
                    messages: &messages,
                    tools: tools,
                    options: options,
                    maxSteps: maxSteps,
                    stopWhen: stopWhen,
                    onStepFinish: onStepFinish,
                    toolOptions: toolOptions,
                    onAgentEvent: emit,
                    onEvent: nil
                )

                let finishEvent = AgentEvent.agentFinished(AgentFinishEvent(result: result))
                emit(finishEvent)
                onFinish?(result)
                continuation.finish()
            } catch {
                let failureEvent = AgentEvent.failed(error)
                emit(failureEvent)
                continuation.finish(throwing: error)
            }
        }
    }
}
