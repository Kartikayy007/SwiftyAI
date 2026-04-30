import Foundation
import Observation
import SwiftUI
import SwiftyAI

struct AICompletionHookExampleView: View {
    @Environment(ProviderSettingsStore.self) private var providerStore
    @State private var completion: AICompletion?
    @State private var modelKey = ""
    @State private var setupError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let completion {
                AICompletionHookCard(completion: completion, modelLabel: providerStore.settings.modelString)
            } else {
                ExampleCard(
                    title: "AICompletion",
                    subtitle: "Uses the SwiftUI hook for prompt, output, loading, errors, and cancellation."
                ) {
                    Text("Configure provider settings, then prepare the hook.")
                        .foregroundStyle(.secondary)

                    HStack {
                        Button {
                            configureCompletion()
                        } label: {
                            Label("Prepare Hook", systemImage: "text.quote")
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

            if let message = completion?.error?.exampleMessage {
                ErrorBanner(message: message)
            }
        }
        .examplePage()
        .task {
            configureCompletionIfNeeded()
        }
        .onChange(of: providerStore.settings) { _, _ in
            configureCompletion()
        }
        .onChange(of: providerStore.apiKey) { _, _ in
            configureCompletion()
        }
        .onDisappear {
            completion?.stop()
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

    private func configureCompletionIfNeeded() {
        if completion == nil || modelKey != currentModelKey {
            configureCompletion()
        }
    }

    private func configureCompletion() {
        let previousInput = completion?.input ?? "Write a concise release note for a SwiftUI AI completion hook."
        completion?.stop()

        do {
            let model: any AIModel = try ModelFactory.makeStreamModel(settings: providerStore.settings, apiKey: providerStore.apiKey)
            let nextCompletion = AICompletion(
                model: model,
                options: GenerationOptions(
                    system: "You write clear developer-facing copy.",
                    temperature: 0.4,
                    maxTokens: 220
                )
            )
            nextCompletion.input = previousInput
            completion = nextCompletion
            modelKey = currentModelKey
            setupError = nil
        } catch {
            completion = nil
            modelKey = ""
            setupError = error.exampleMessage
        }
    }
}

private struct AICompletionHookCard: View {
    @Bindable var completion: AICompletion
    let modelLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ExampleCard(
                title: "AICompletion",
                subtitle: "The hook owns input, output, loading state, and errors."
            ) {
                PromptEditor(title: "Prompt", text: $completion.input)

                HStack {
                    LoadingButton(
                        title: "Generate",
                        systemImage: "sparkles",
                        isLoading: completion.isLoading
                    ) {
                        completion.send()
                    }

                    Button {
                        completion.stop()
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .buttonStyle(.bordered)
                    .disabled(!completion.isLoading)

                    Button {
                        completion.reset()
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(.borderless)

                    Text(modelLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            ExampleCard(title: "Completion") {
                ResponsePanel(title: "Output", text: completion.output)
            }
        }
    }
}
