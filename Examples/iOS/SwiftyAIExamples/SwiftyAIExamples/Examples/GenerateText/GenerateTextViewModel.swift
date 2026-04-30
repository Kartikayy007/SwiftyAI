import Foundation
import Observation
import SwiftyAI

@MainActor
@Observable
final class GenerateTextViewModel {
    var prompt = "Write a concise release note for an iOS AI SDK that added streaming, object generation, chat, and tool calling."
    var systemPrompt = "You write clear developer-facing copy."
    var responseText = ""
    var usage: TokenUsage?
    var finishReason: String?
    var state: ExampleState<Void> = .idle

    func run(settings: ProviderSettings, apiKey: String) async {
        state = .loading
        responseText = ""
        usage = nil
        finishReason = nil

        do {
            let model = try ModelFactory.makeStreamModel(settings: settings, apiKey: apiKey)
            let response = try await generateText(
                model: model,
                prompt: prompt,
                options: GenerationOptions(system: systemPrompt, temperature: 0.4, maxTokens: 280)
            )
            responseText = response.text
            usage = response.usage
            finishReason = response.finishReason
            state = .success(())
        } catch {
            state = .failure(error.exampleMessage)
        }
    }
}
