import SwiftUI

struct EmbeddingsExampleView: View {
    @Environment(ProviderSettingsStore.self) private var providerStore
    @State private var viewModel = EmbeddingsExampleViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ExampleCard(
                title: "embed + embedMany",
                subtitle: "Embeds a query and documents, then ranks them with cosineSimilarity."
            ) {
                PromptEditor(title: "Query", text: $viewModel.query, minHeight: 80)
                PromptEditor(title: "Documents", text: $viewModel.documentsText)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Embedding Model")
                        .font(.subheadline.weight(.medium))

                    TextField("Use the default for OpenAI or Gemini", text: $viewModel.customModel)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    LoadingButton(
                        title: "Compare",
                        systemImage: "square.grid.3x3",
                        isLoading: viewModel.state.isLoading
                    ) {
                        Task {
                            await viewModel.run(settings: providerStore.settings, apiKey: providerStore.apiKey)
                        }
                    }

                    Text(EmbeddingExampleDefaults.modelLabel(
                        settings: providerStore.settings,
                        customModel: viewModel.customModel
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            if case .failure(let message) = viewModel.state {
                ErrorBanner(message: message)
            }

            ExampleCard(title: "Similarity Results") {
                if viewModel.state.isLoading {
                    ProgressView("Embedding text")
                        .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
                } else if viewModel.results.isEmpty {
                    Text("Run the example to rank documents by similarity.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(viewModel.results) { result in
                            EmbeddingResultRow(result: result)
                        }

                        HStack(spacing: 12) {
                            if let modelName = viewModel.modelName {
                                Text(modelName)
                            }
                            if let vectorDimensions = viewModel.vectorDimensions {
                                Text("\(vectorDimensions) dimensions")
                            }
                            if let inputTokens = viewModel.inputTokens {
                                Text("\(inputTokens) input tokens")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .examplePage()
    }
}

private struct EmbeddingResultRow: View {
    let result: EmbeddingSearchResult

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(result.score, format: .number.precision(.fractionLength(3)))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 52, alignment: .trailing)

            Text(result.document)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .padding(10)
        .background(Theme.mutedBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous))
    }
}
