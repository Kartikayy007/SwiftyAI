import Foundation
import Observation
import SwiftyAI

@MainActor
@Observable
final class GenerationOptionsViewModel {
    var prompt = "Give three practical tips for designing streaming AI interfaces on iOS."
    var systemPrompt = "Respond as a senior iOS engineer."
    var temperature = 0.5
    var maxTokens = 220.0
    var retryAttempts = 1.0
    var stopSequences = ""
    var cacheKey = ""
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
                options: options
            )
            responseText = response.text
            usage = response.usage
            finishReason = response.finishReason
            state = .success(())
        } catch {
            state = .failure(error.exampleMessage)
        }
    }

    private var options: GenerationOptions {
        let stops = stopSequences
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let promptCaching = cacheKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? nil
            : PromptCachingOptions(cacheKey: cacheKey)

        return GenerationOptions(
            system: systemPrompt,
            temperature: temperature,
            maxTokens: Int(maxTokens),
            stopSequences: stops.isEmpty ? nil : stops,
            retryPolicy: RetryPolicy(maxAttempts: Int(retryAttempts)),
            promptCaching: promptCaching
        )
    }
}
