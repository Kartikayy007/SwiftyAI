import SwiftUI

struct MultimodalExampleView: View {
    @Environment(ProviderSettingsStore.self) private var providerStore
    @State private var viewModel = MultimodalExampleViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ExampleCard(
                title: "multimodal prompt",
                subtitle: "Sends multipart AIMessageContent to generateText."
            ) {
                PromptEditor(title: "Prompt", text: $viewModel.prompt)
                PromptEditor(title: "System", text: $viewModel.systemPrompt, minHeight: 80)

                Picker("Input", selection: $viewModel.selectedKind) {
                    ForEach(MultimodalInputKind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.selectedKind) { _, newValue in
                    viewModel.select(newValue)
                }

                if viewModel.selectedKind == .imageURL
                    || viewModel.selectedKind == .pdfURL
                    || viewModel.selectedKind == .videoURL {
                    TextField("URL", text: $viewModel.urlText)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                HStack {
                    LoadingButton(
                        title: "Run",
                        systemImage: "paperclip",
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
