import Foundation
import Observation
import SwiftyAI

@MainActor
@Observable
final class GenerateObjectViewModel {
    enum Mode: String, CaseIterable, Identifiable {
        case object
        case array
        case enumeration
        case stream

        var id: String { rawValue }
        var title: String {
            switch self {
            case .object: "Object"
            case .array: "Array"
            case .enumeration: "Enum"
            case .stream: "Stream"
            }
        }
    }

    var mode: Mode = .object
    var prompt = """
    Turn this into a structured recipe:
    Chickpea lunch bowl for two. Mix chickpeas, cucumber, tomato, parsley, lemon juice, olive oil, salt, and pepper. Serve over rice. Takes about 15 minutes.
    """
    var recipe: RecipeSummary?
    var ingredients: [IngredientIdea] = []
    var category: MealCategory?
    var partialJSON = ""
    var validationIssues: [AISchemaValidationIssue] = []
    var usage: TokenUsage?
    var finishReason: String?
    var state: ExampleState<Void> = .idle

    func run(settings: ProviderSettings, apiKey: String) async {
        state = .loading
        recipe = nil
        ingredients = []
        category = nil
        partialJSON = ""
        validationIssues = []
        usage = nil
        finishReason = nil

        do {
            let model = try ModelFactory.makeStreamModel(settings: settings, apiKey: apiKey)
            switch mode {
            case .object:
                let response = try await generateObject(
                    model: model,
                    prompt: prompt,
                    output: .object(RecipeSummary.self),
                    options: GenerationOptions(system: "Extract facts into the requested JSON shape.")
                )
                recipe = response.object
                usage = response.usage
                finishReason = response.finishReason
            case .array:
                let response = try await generateObject(
                    model: model,
                    prompt: "List 4 ingredient ideas for this meal with each ingredient's role.\n\(prompt)",
                    output: Output<[IngredientIdea]>.array(IngredientIdea.self)
                )
                ingredients = response.object
                usage = response.usage
                finishReason = response.finishReason
            case .enumeration:
                let response = try await generateObject(
                    model: model,
                    prompt: "Classify this meal as breakfast, lunch, dinner, or snack.\n\(prompt)",
                    output: Output<MealCategory>.enumeration(MealCategory.self)
                )
                category = response.object
                usage = response.usage
                finishReason = response.finishReason
            case .stream:
                let stream = streamObject(
                    model: model,
                    prompt: prompt,
                    output: Output<RecipeSummary>.object(RecipeSummary.self),
                    options: GenerationOptions(system: "Extract facts into the requested JSON shape.")
                )
                for try await chunk in stream {
                    partialJSON = chunk.partialJSON
                    validationIssues = chunk.validationIssues
                    usage = chunk.usage ?? usage
                    finishReason = chunk.finishReason ?? finishReason
                    if let object = chunk.object ?? chunk.partialObject {
                        recipe = object
                    }
                }
            }
            state = .success(())
        } catch {
            state = .failure(error.exampleMessage)
        }
    }
}
