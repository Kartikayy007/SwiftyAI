import SwiftUI

struct ToolsExampleView: View {
    @Environment(ProviderSettingsStore.self) private var providerStore
    @State private var viewModel = ToolsExampleViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ExampleCard(
                title: "Tools",
                subtitle: "Runs generateWithTools and streamWithTools with local Swift functions."
            ) {
                PromptEditor(title: "Prompt", text: $viewModel.prompt)

                HStack {
                    LoadingButton(
                        title: "Generate",
                        systemImage: "wrench.and.screwdriver",
                        isLoading: viewModel.state.isLoading && !viewModel.isStreamingMode
                    ) {
                        Task {
                            await viewModel.run(settings: providerStore.settings, apiKey: providerStore.apiKey)
                        }
                    }

                    LoadingButton(
                        title: "Stream",
                        systemImage: "dot.radiowaves.left.and.right",
                        isLoading: viewModel.state.isLoading && viewModel.isStreamingMode
                    ) {
                        viewModel.stream(settings: providerStore.settings, apiKey: providerStore.apiKey)
                    }

                    Button {
                        viewModel.stop()
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .buttonStyle(.bordered)
                }
            }

            if case .failure(let message) = viewModel.state {
                ErrorBanner(message: message)
            }

            ExampleCard(title: "Final Answer") {
                ResponsePanel(title: "Text", text: viewModel.finalText)
                UsageBadge(usage: viewModel.usage, finishReason: viewModel.finishReason)
            }

            ExampleCard(title: "Tool Timeline") {
                if viewModel.events.isEmpty {
                    Text("Tool calls and step results appear here.")
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(viewModel.events) { event in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.title)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Text(event.detail)
                                    .font(.callout.monospaced())
                                    .textSelection(.enabled)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous))
                        }
                    }
                }
            }
        }
        .examplePage()
    }
}
