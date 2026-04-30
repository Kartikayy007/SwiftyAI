import SwiftUI
import SwiftyAI

struct ChatExampleView: View {
    @Environment(ProviderSettingsStore.self) private var providerStore
    @State private var viewModel = ChatViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ExampleCard(
                title: "SwiftyChat",
                subtitle: "Maintains message history and streams assistant replies into the latest message."
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    chatTranscript

                    HStack(alignment: .bottom) {
                        TextField("Message", text: $viewModel.input, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(1...4)

                        Button {
                            viewModel.send(settings: providerStore.settings, apiKey: providerStore.apiKey)
                        } label: {
                            Image(systemName: "paperplane.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.state.isLoading)
                        .accessibilityLabel("Send")

                        Button {
                            viewModel.stop()
                        } label: {
                            Image(systemName: "stop.fill")
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Stop")
                    }

                    Button {
                        viewModel.clear()
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                    .buttonStyle(.borderless)
                }
            }

            if case .failure(let message) = viewModel.state {
                ErrorBanner(message: message)
            }
        }
        .examplePage()
    }

    private var chatTranscript: some View {
        VStack(alignment: .leading, spacing: 10) {
            if viewModel.messages.isEmpty {
                Text("Send a message to start a SwiftyChat session.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 180, alignment: .center)
            } else {
                ForEach(viewModel.messages) { message in
                    ChatBubble(message: message)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 260, alignment: .topLeading)
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous))
    }
}

private struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .assistant {
                bubble
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                bubble
            }
        }
    }

    private var bubble: some View {
        Text(message.content)
            .padding(10)
            .background(message.role == .assistant ? Theme.mutedBackground : Color.accentColor.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous))
            .textSelection(.enabled)
    }
}
