import Foundation
import Observation
import SwiftyAI

@MainActor
@Observable
final class StreamTextViewModel {
    var prompt = "Stream a short explanation of how server-sent events make AI responses feel faster in mobile apps."
    var responseText = ""
    var chunkCount = 0
    var usage: TokenUsage?
    var finishReason: String?
    var state: ExampleState<Void> = .idle

    private var streamTask: Task<Void, Never>?

    func start(settings: ProviderSettings, apiKey: String) {
        stop()
        state = .loading
        responseText = ""
        chunkCount = 0
        usage = nil
        finishReason = nil

        streamTask = Task {
            do {
                let model = try ModelFactory.makeStreamModel(settings: settings, apiKey: apiKey)
                let stream = streamText(
                    model: model,
                    prompt: prompt,
                    options: GenerationOptions(system: "Be direct and concrete.", temperature: 0.3)
                )

                for try await chunk in stream {
                    if Task.isCancelled { return }
                    if !chunk.text.isEmpty {
                        responseText += chunk.text
                        chunkCount += 1
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
}
