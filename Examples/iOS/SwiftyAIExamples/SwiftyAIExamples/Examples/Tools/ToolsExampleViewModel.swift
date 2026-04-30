import Foundation
import Observation
import SwiftyAI

struct ToolEvent: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}

@MainActor
@Observable
final class ToolsExampleViewModel {
    var prompt = "Check order B200, calculate an 18% tip on a 42.50 bill, then summarize both results."
    var finalText = ""
    var events: [ToolEvent] = []
    var state: ExampleState<Void> = .idle
    var usage: TokenUsage?
    var finishReason: String?
    var isStreamingMode = false
    var requiresApproval = false
    var interceptOrderID = false
    var parallelToolCalls = false

    private var streamTask: Task<Void, Never>?

    func run(settings: ProviderSettings, apiKey: String) async {
        isStreamingMode = false
        reset()
        state = .loading

        do {
            let model = try ModelFactory.makeToolModel(settings: settings, apiKey: apiKey)
            let result = try await generateWithTools(
                model: model,
                prompt: prompt,
                tools: DemoTools.all,
                options: GenerationOptions(system: "Use tools when useful. Then give a brief final answer."),
                maxSteps: 5,
                onStepFinish: { [weak self] step in
                    Task { @MainActor in
                        self?.append(step: step)
                    }
                },
                toolOptions: toolOptions()
            )
            finalText = result.text
            usage = result.usage
            finishReason = result.finishReason
            state = .success(())
        } catch {
            state = .failure(error.exampleMessage)
        }
    }

    func stream(settings: ProviderSettings, apiKey: String) {
        stop()
        isStreamingMode = true
        reset()
        state = .loading

        streamTask = Task {
            do {
                let model = try ModelFactory.makeToolModel(settings: settings, apiKey: apiKey)
                let stream = streamWithTools(
                    model: model,
                    prompt: prompt,
                    tools: DemoTools.all,
                    options: GenerationOptions(system: "Use tools when useful. Then give a brief final answer."),
                    maxSteps: 5,
                    onStepFinish: { [weak self] step in
                        Task { @MainActor in self?.append(step: step) }
                    },
                    onFinish: { [weak self] result in
                        Task { @MainActor in
                            self?.usage = result.usage
                            self?.finishReason = result.finishReason
                        }
                    },
                    toolOptions: toolOptions()
                )

                for try await chunk in stream {
                    if Task.isCancelled { return }
                    if !chunk.text.isEmpty {
                        finalText += chunk.text
                    }
                    if let call = chunk.toolCall {
                        events.append(ToolEvent(title: "Tool call", detail: "\(call.name) \(call.arguments)"))
                    }
                    if let result = chunk.toolResult {
                        events.append(ToolEvent(title: "Tool result", detail: "\(result.name): \(result.content)"))
                    }
                    usage = chunk.usage ?? usage
                    finishReason = chunk.finishReason ?? finishReason
                }
                state = .success(())
            } catch {
                state = .failure(error.exampleMessage)
            }
            streamTask = nil
        }
    }

    func stop() {
        streamTask?.cancel()
        streamTask = nil
        if state.isLoading {
            state = .idle
        }
    }

    private func reset() {
        finalText = ""
        events = []
        usage = nil
        finishReason = nil
    }

    private func toolOptions() -> ToolExecutionOptions {
        let shouldInterceptOrderID = interceptOrderID
        let shouldRequireApproval = requiresApproval
        let shouldRunParallel = parallelToolCalls

        ToolExecutionOptions(
            approval: shouldRequireApproval ? { call in
                call.name == "lookup_demo_order" ? .execute : .execute
            } : nil,
            onToolCall: { call in
                guard shouldInterceptOrderID, call.name == "lookup_demo_order" else {
                    return .execute
                }
                return .replaceArguments(#"{"orderID":"B200"}"#)
            },
            onToolResult: { [weak self] result in
                Task { @MainActor in
                    self?.events.append(ToolEvent(title: "Tool result callback", detail: "\(result.name): \(result.content)"))
                }
            },
            onTelemetry: { [weak self] event in
                Task { @MainActor in
                    self?.events.append(ToolEvent(title: "Telemetry", detail: String(describing: event)))
                }
            },
            parallelToolCalls: shouldRunParallel
        )
    }

    private func append(step: AIStep) {
        if !step.text.isEmpty {
            events.append(ToolEvent(title: "Step \(step.index) text", detail: step.text))
        }
        for call in step.toolCalls {
            events.append(ToolEvent(title: "Step \(step.index) call", detail: "\(call.name) \(call.arguments)"))
        }
        for result in step.toolResults {
            events.append(ToolEvent(title: "Step \(step.index) result", detail: "\(result.name): \(result.content)"))
        }
    }
}
