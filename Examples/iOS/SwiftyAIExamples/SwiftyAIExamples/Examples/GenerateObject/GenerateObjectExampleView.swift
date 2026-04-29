import SwiftUI

struct GenerateObjectExampleView: View {
    @Environment(ProviderSettingsStore.self) private var providerStore
    @State private var viewModel = GenerateObjectViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ExampleCard(
                title: "generateObject",
                subtitle: "Uses JSONSchemaConvertible and decodes the model output into a Swift type."
            ) {
                PromptEditor(title: "Prompt", text: $viewModel.prompt, minHeight: 150)
                LoadingButton(
                    title: "Extract",
                    systemImage: "curlybraces",
                    isLoading: viewModel.state.isLoading
                ) {
                    Task {
                        await viewModel.run(settings: providerStore.settings, apiKey: providerStore.apiKey)
                    }
                }
            }

            if case .failure(let message) = viewModel.state {
                ErrorBanner(message: message)
            }

            ExampleCard(title: "Decoded Object") {
                if let recipe = viewModel.recipe {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(recipe.title)
                            .font(.title3.weight(.semibold))
                        Label("\(recipe.servings) servings", systemImage: "person.2")
                        Label("\(recipe.prepMinutes) minutes", systemImage: "clock")
                        Divider()
                        Text("Ingredients").font(.headline)
                        ForEach(recipe.ingredients, id: \.self) { ingredient in
                            Text(ingredient)
                        }
                        Divider()
                        Text("Steps").font(.headline)
                        ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                            Text("\(index + 1). \(step)")
                        }
                    }
                } else {
                    Text("Run the example to decode a RecipeSummary.")
                        .foregroundStyle(.secondary)
                }
                UsageBadge(usage: viewModel.usage, finishReason: viewModel.finishReason)
            }
        }
        .examplePage()
    }
}
