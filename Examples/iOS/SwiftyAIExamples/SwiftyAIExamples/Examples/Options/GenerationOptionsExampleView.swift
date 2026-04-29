import SwiftUI

struct GenerationOptionsExampleView: View {
    @Environment(ProviderSettingsStore.self) private var providerStore
    @State private var viewModel = GenerationOptionsViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ExampleCard(
                title: "GenerationOptions",
                subtitle: "Adjust common options and pass them into generateText."
            ) {
                PromptEditor(title: "Prompt", text: $viewModel.prompt)
                PromptEditor(title: "System", text: $viewModel.systemPrompt, minHeight: 80)

                VStack(alignment: .leading, spacing: 12) {
                    LabeledContent("Temperature", value: viewModel.temperature.formatted(.number.precision(.fractionLength(2))))
                    Slider(value: $viewModel.temperature, in: 0...1)

                    LabeledContent("Max tokens", value: Int(viewModel.maxTokens).formatted())
                    Slider(value: $viewModel.maxTokens, in: 64...1000, step: 1)

                    LabeledContent("Retry attempts", value: Int(viewModel.retryAttempts).formatted())
                    Stepper("", value: $viewModel.retryAttempts, in: 1...5, step: 1)
                        .labelsHidden()

                    TextField("Stop sequences, comma separated", text: $viewModel.stopSequences)
                        .textFieldStyle(.roundedBorder)

                    TextField("Prompt cache key", text: $viewModel.cacheKey)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                LoadingButton(
                    title: "Run",
                    systemImage: "slider.horizontal.3",
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

            ExampleCard(title: "Response") {
                ResponsePanel(title: "Text", text: viewModel.responseText)
                UsageBadge(usage: viewModel.usage, finishReason: viewModel.finishReason)
            }
        }
        .examplePage()
    }
}
