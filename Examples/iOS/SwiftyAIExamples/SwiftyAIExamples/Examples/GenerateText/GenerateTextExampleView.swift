import SwiftUI

struct GenerateTextExampleView: View {
    @Environment(ProviderSettingsStore.self) private var providerStore
    @State private var viewModel = GenerateTextViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ExampleCard(
                title: "generateText",
                subtitle: "Runs one request and returns a complete AIResponse."
            ) {
                PromptEditor(title: "Prompt", text: $viewModel.prompt)
                PromptEditor(title: "System", text: $viewModel.systemPrompt, minHeight: 80)

                HStack {
                    LoadingButton(
                        title: "Generate",
                        systemImage: "sparkles",
                        isLoading: viewModel.state.isLoading
                    ) {
                        Task {
                            await viewModel.run(settings: providerStore.settings, apiKey: providerStore.apiKey)
                        }
                    }
                    Text(providerStore.settings.modelString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if case .failure(let message) = viewModel.state {
                ErrorBanner(message: message)
            }

            ExampleCard(title: "Response") {
                ResponsePanel(title: "Text", text: viewModel.responseText)
                UsageBadge(usage: viewModel.usage, finishReason: viewModel.finishReason)
            }
        }
        .examplePage()
    }
}
