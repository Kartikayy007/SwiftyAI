import Foundation

public func generateWithTools(
    model: some AIToolCallingModel,
    prompt: String,
    tools: [AITool],
    options: GenerationOptions = GenerationOptions(),
    maxSteps: Int = 5,
    stopWhen: [AIStopCondition] = [isLoopFinished()],
    onStepFinish: ((AIStep) -> Void)? = nil
) async throws -> AIStepResult {
    var messages = initialAgentMessages(prompt: prompt, options: options)
    return try await runToolLoop(
        model: model,
        messages: &messages,
        tools: tools,
        options: options,
        maxSteps: maxSteps,
        stopWhen: stopWhen,
        onStepFinish: onStepFinish,
        onEvent: nil
    )
}

public func generateWithTools(
    model: String,
    prompt: String,
    tools: [AITool],
    options: GenerationOptions = GenerationOptions(),
    maxSteps: Int = 5,
    stopWhen: [AIStopCondition] = [isLoopFinished()],
    onStepFinish: ((AIStep) -> Void)? = nil
) async throws -> AIStepResult {
    let resolved = try await AIRegistry.shared.resolve(model)
    guard let toolModel = resolved as? any AIToolCallingModel else {
        throw AIError.unsupportedFeature("Tool calling is not implemented by this provider")
    }
    var messages = initialAgentMessages(prompt: prompt, options: options)
    return try await runToolLoop(
        model: toolModel,
        messages: &messages,
        tools: tools,
        options: options,
        maxSteps: maxSteps,
        stopWhen: stopWhen,
        onStepFinish: onStepFinish,
        onEvent: nil
    )
}

public func streamWithTools(
    model: some AIToolCallingModel,
    prompt: String,
    tools: [AITool],
    options: GenerationOptions = GenerationOptions(),
    maxSteps: Int = 5,
    stopWhen: [AIStopCondition] = [isLoopFinished()],
    onChunk: ((AIAgentChunk) -> Void)? = nil,
    onStepFinish: ((AIStep) -> Void)? = nil,
    onFinish: ((AIStepResult) -> Void)? = nil
) -> AsyncThrowingStream<AIAgentChunk, Error> {
    AsyncThrowingStream { continuation in
        Task {
            do {
                var messages = initialAgentMessages(prompt: prompt, options: options)
                let result = try await runToolLoop(
                    model: model,
                    messages: &messages,
                    tools: tools,
                    options: options,
                    maxSteps: maxSteps,
                    stopWhen: stopWhen,
                    onStepFinish: onStepFinish
                ) { chunk in
                    onChunk?(chunk)
                    continuation.yield(chunk)
                }
                onFinish?(result)
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}

public func streamWithTools(
    model: String,
    prompt: String,
    tools: [AITool],
    options: GenerationOptions = GenerationOptions(),
    maxSteps: Int = 5,
    stopWhen: [AIStopCondition] = [isLoopFinished()],
    onChunk: ((AIAgentChunk) -> Void)? = nil,
    onStepFinish: ((AIStep) -> Void)? = nil,
    onFinish: ((AIStepResult) -> Void)? = nil
) -> AsyncThrowingStream<AIAgentChunk, Error> {
    AsyncThrowingStream { continuation in
        Task {
            do {
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
                    onStepFinish: onStepFinish
                ) { chunk in
                    onChunk?(chunk)
                    continuation.yield(chunk)
                }
                onFinish?(result)
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}

private func runToolLoop(
    model: any AIToolCallingModel,
    messages: inout [AIAgentMessage],
    tools: [AITool],
    options: GenerationOptions,
    maxSteps: Int,
    stopWhen: [AIStopCondition],
    onStepFinish: ((AIStep) -> Void)?,
    onEvent: ((AIAgentChunk) -> Void)?
) async throws -> AIStepResult {
    var steps: [AIStep] = []
    var finalText = ""
    var lastUsage: TokenUsage?
    var lastFinishReason: String?

    for index in 1...max(1, maxSteps) {
        if Task.isCancelled {
            throw CancellationError()
        }

        let response = try await model.generateStep(messages: messages, tools: tools, options: options)
        finalText += response.text
        lastUsage = response.usage ?? lastUsage
        lastFinishReason = response.finishReason ?? lastFinishReason

        if !response.text.isEmpty {
            onEvent?(AIAgentChunk(text: response.text, stepIndex: index, usage: response.usage, finishReason: response.finishReason))
        }
        for toolCall in response.toolCalls {
            onEvent?(AIAgentChunk(stepIndex: index, toolCall: toolCall))
        }

        messages.append(.init(role: "assistant", content: response.text.isEmpty ? nil : response.text, toolCalls: response.toolCalls))

        var step = AIStep(
            index: index,
            text: response.text,
            toolCalls: response.toolCalls,
            usage: response.usage,
            finishReason: response.finishReason
        )

        if shouldStop(step: step, maxSteps: maxSteps, stopWhen: stopWhen) {
            steps.append(step)
            onStepFinish?(step)
            return AIStepResult(text: finalText, steps: steps, usage: lastUsage, finishReason: lastFinishReason)
        }

        let toolResults = try await executeToolCalls(response.toolCalls, tools: tools)
        for result in toolResults {
            messages.append(.init(role: "tool", content: result.content, toolCallID: result.toolCallID))
            onEvent?(AIAgentChunk(stepIndex: index, toolResult: result))
        }

        step = AIStep(
            index: index,
            text: response.text,
            toolCalls: response.toolCalls,
            toolResults: toolResults,
            usage: response.usage,
            finishReason: response.finishReason
        )
        steps.append(step)
        onStepFinish?(step)

        if response.toolCalls.isEmpty {
            return AIStepResult(text: finalText, steps: steps, usage: lastUsage, finishReason: lastFinishReason)
        }
    }

    return AIStepResult(
        text: finalText,
        steps: steps,
        usage: lastUsage,
        finishReason: "max_steps",
        isMaxStepsExceeded: true
    )
}

private func initialAgentMessages(prompt: String, options: GenerationOptions) -> [AIAgentMessage] {
    var messages: [AIAgentMessage] = []
    if let system = options.system {
        messages.append(.init(role: "system", content: system))
    }
    messages.append(.init(role: "user", content: prompt))
    return messages
}

private func shouldStop(step: AIStep, maxSteps: Int, stopWhen: [AIStopCondition]) -> Bool {
    let context = AIStopContext(step: step, maxSteps: maxSteps)
    return stopWhen.contains { $0.evaluate(context) }
}

private func executeToolCalls(_ calls: [AIToolCall], tools: [AITool]) async throws -> [AIToolResult] {
    var results: [AIToolResult] = []
    for call in calls {
        guard let tool = tools.first(where: { $0.name == call.name }) else {
            results.append(.init(toolCallID: call.id, name: call.name, content: AIError.toolNotFound(call.name).localizedDescription, isError: true))
            continue
        }

        do {
            let content = try await tool.execute(parseToolArguments(call.arguments))
            results.append(.init(toolCallID: call.id, name: call.name, content: content))
        } catch {
            results.append(.init(toolCallID: call.id, name: call.name, content: error.localizedDescription, isError: true))
        }
    }
    return results
}

private func parseToolArguments(_ arguments: String) -> [String: Any] {
    guard let data = arguments.data(using: .utf8),
          let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        return ["_raw": arguments]
    }
    return object
}
