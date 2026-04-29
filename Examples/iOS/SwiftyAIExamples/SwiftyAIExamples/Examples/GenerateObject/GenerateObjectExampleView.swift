import SwiftUI

struct GenerateObjectExampleView: View {
    @Environment(ProviderSettingsStore.self) private var providerStore
    @State private var viewModel = GenerateObjectViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ExampleCard(
                title: "Structured Output",
                subtitle: "Demonstrates Output.object, Output.array, Output.enum, and streamObject."
            ) {
                Picker("Mode", selection: $viewModel.mode) {
                    ForEach(GenerateObjectViewModel.Mode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                PromptEditor(title: "Prompt", text: $viewModel.prompt, minHeight: 150)
                LoadingButton(
                    title: viewModel.mode == .stream ? "Stream" : "Extract",
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
                if viewModel.mode == .array {
                    if viewModel.ingredients.isEmpty {
                        Text("Run the array example to decode ingredient ideas.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.ingredients) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name).font(.headline)
                                Text(item.role).foregroundStyle(.secondary)
                            }
                        }
                    }
                } else if viewModel.mode == .enumeration {
                    Text(viewModel.category?.rawValue ?? "Run the enum example to decode a category.")
                        .font(.title3.weight(.semibold))
                } else if let recipe = viewModel.recipe {
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

                if viewModel.mode == .stream {
                    Divider()
                    ResponsePanel(title: "Partial JSON", text: viewModel.partialJSON)
                    if !viewModel.validationIssues.isEmpty {
                        ForEach(viewModel.validationIssues, id: \.path) { issue in
                            Text("\(issue.path): \(issue.message)")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                UsageBadge(usage: viewModel.usage, finishReason: viewModel.finishReason)
            }
        }
        .examplePage()
    }
}
