import Foundation
import Observation
import SwiftyAI

@MainActor
@Observable
final class GenerateObjectViewModel {
    var prompt = """
    Turn this into a structured recipe:
    Chickpea lunch bowl for two. Mix chickpeas, cucumber, tomato, parsley, lemon juice, olive oil, salt, and pepper. Serve over rice. Takes about 15 minutes.
    """
    var recipe: RecipeSummary?
    var usage: TokenUsage?
    var finishReason: String?
    var state: ExampleState<Void> = .idle

    func run(settings: ProviderSettings, apiKey: String) async {
        state = .loading
        recipe = nil
        usage = nil
        finishReason = nil

        do {
            let model = try ModelFactory.makeStreamModel(settings: settings, apiKey: apiKey)
            let response = try await generateObject(
                model: model,
                prompt: prompt,
                as: RecipeSummary.self,
                options: GenerationOptions(system: "Extract facts into the requested JSON shape.")
            )
            recipe = response.object
            usage = response.usage
            finishReason = response.finishReason
            state = .success(())
        } catch {
            state = .failure(error.exampleMessage)
        }
    }
}
