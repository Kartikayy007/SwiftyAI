import SwiftUI

struct StreamTextExampleView: View {
    @Environment(ProviderSettingsStore.self) private var providerStore
    @State private var viewModel = StreamTextViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ExampleCard(
                title: "streamText",
                subtitle: "Consumes an AsyncThrowingStream of AIStreamChunk values."
            ) {
                PromptEditor(title: "Prompt", text: $viewModel.prompt)

                HStack {
                    LoadingButton(
                        title: "Start",
                        systemImage: "play.fill",
                        isLoading: viewModel.state.isLoading
                    ) {
                        viewModel.start(settings: providerStore.settings, apiKey: providerStore.apiKey)
                    }

                    Button {
                        viewModel.stop()
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .buttonStyle(.bordered)

                    Text("\(viewModel.chunkCount) chunks")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if case .failure(let message) = viewModel.state {
                ErrorBanner(message: message)
            }

            ExampleCard(title: "Live Output") {
                ResponsePanel(title: "Stream", text: viewModel.responseText)
                UsageBadge(usage: viewModel.usage, finishReason: viewModel.finishReason)
            }
        }
        .examplePage()
    }
}
