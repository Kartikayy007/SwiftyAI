import Foundation
import Observation
import SwiftUI
import SwiftyAI

struct AIChatHookExampleView: View {
    @Environment(ProviderSettingsStore.self) private var providerStore
    @State private var chat: AIChat?
    @State private var modelKey = ""
    @State private var setupError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let chat {
                AIChatHookCard(chat: chat, modelLabel: providerStore.settings.modelString)
            } else {
                ExampleCard(
                    title: "AIChat",
                    subtitle: "Uses the SwiftUI hook for messages, input, loading, errors, and cancellation."
                ) {
                    Text("Configure provider settings, then prepare the hook.")
                        .foregroundStyle(.secondary)

                    HStack {
                        Button {
                            configureChat()
                        } label: {
                            Label("Prepare Hook", systemImage: "bubble.left.and.bubble.right")
                        }
                        .buttonStyle(.borderedProminent)

                        Text(providerStore.settings.modelString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let setupError {
                ErrorBanner(message: setupError)
            }

            if let message = chat?.error?.exampleMessage {
                ErrorBanner(message: message)
            }
        }
        .examplePage()
        .task {
            configureChatIfNeeded()
        }
        .onChange(of: providerStore.settings) { _, _ in
            configureChat()
        }
        .onChange(of: providerStore.apiKey) { _, _ in
            configureChat()
        }
        .onDisappear {
            chat?.stop()
        }
    }

    private var currentModelKey: String {
        [
            providerStore.settings.provider.rawValue,
            providerStore.settings.model,
            providerStore.settings.accountID,
            providerStore.settings.ollamaBaseURL,
            providerStore.apiKey
        ].joined(separator: ":")
    }

    private func configureChatIfNeeded() {
        if chat == nil || modelKey != currentModelKey {
            configureChat()
        }
    }

    private func configureChat() {
        let previousInput = chat?.input ?? "Explain how AIChat keeps SwiftUI chat views small."
        chat?.stop()

        do {
            let model = try ModelFactory.makeStreamModel(settings: providerStore.settings, apiKey: providerStore.apiKey)
            let nextChat = AIChat(
                model: model,
                systemPrompt: "You explain SwiftyAI example app code in concise terms.",
                maxMessages: 16,
                options: GenerationOptions(temperature: 0.3)
            )
            nextChat.input = previousInput
            chat = nextChat
            modelKey = currentModelKey
            setupError = nil
        } catch {
            chat = nil
            modelKey = ""
            setupError = error.exampleMessage
        }
    }
}

private struct AIChatHookCard: View {
    @Bindable var chat: AIChat
    let modelLabel: String

    var body: some View {
        ExampleCard(
            title: "AIChat",
            subtitle: "The hook owns input, messages, loading state, and errors."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                transcript

                HStack(alignment: .bottom) {
                    TextField("Message", text: $chat.input, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)

                    Button {
                        chat.send()
                    } label: {
                        Image(systemName: chat.isLoading ? "hourglass" : "paperplane.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSend)
                    .accessibilityLabel("Send")

                    Button {
                        chat.stop()
                    } label: {
                        Image(systemName: "stop.fill")
                    }
                    .buttonStyle(.bordered)
                    .disabled(!chat.isLoading)
                    .accessibilityLabel("Stop")
                }

                HStack {
                    Button {
                        chat.reset()
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(.borderless)

                    Spacer()

                    if chat.isLoading {
                        ProgressView()
                    }

                    Text(modelLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var canSend: Bool {
        !chat.isLoading && !chat.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var transcript: some View {
        VStack(alignment: .leading, spacing: 10) {
            if chat.messages.isEmpty {
                Text("Send a message to start an AIChat hook session.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 180, alignment: .center)
            } else {
                ForEach(chat.messages) { message in
                    AIChatHookBubble(message: message)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 260, alignment: .topLeading)
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous))
    }
}

private struct AIChatHookBubble: View {
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
        Text(message.content.isEmpty ? "Thinking..." : message.content)
            .padding(10)
            .background(message.role == .assistant ? Theme.mutedBackground : Color.accentColor.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous))
            .textSelection(.enabled)
    }
}
