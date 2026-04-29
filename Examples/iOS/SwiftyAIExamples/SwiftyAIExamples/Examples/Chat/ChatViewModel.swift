import Foundation
import Observation
import SwiftyAI

@MainActor
@Observable
final class ChatViewModel {
    var input = "How should I decide between generateText and streamText?"
    var chat: SwiftyChat?
    var state: ExampleState<Void> = .idle

    private var sendTask: Task<Void, Never>?
    private var currentModelKey: String?

    var messages: [ChatMessage] {
        chat?.messages ?? []
    }

    func send(settings: ProviderSettings, apiKey: String) {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let text = input
        input = ""
        state = .loading

        sendTask = Task {
            do {
                let modelKey = "\(settings.provider.rawValue):\(settings.model):\(settings.accountID):\(settings.ollamaBaseURL)"
                if chat == nil || currentModelKey != modelKey {
                    let model = try ModelFactory.makeStreamModel(settings: settings, apiKey: apiKey)
                    chat = SwiftyChat(
                        model: model,
                        systemPrompt: "You are a concise assistant explaining SwiftyAI examples.",
                        maxMessages: 16
                    )
                    currentModelKey = modelKey
                }
                try await chat?.send(text)
                state = .success(())
            } catch {
                state = .failure(error.exampleMessage)
            }
            sendTask = nil
        }
    }

    func stop() {
        sendTask?.cancel()
        chat?.stop()
        sendTask = nil
        state = .idle
    }

    func clear() {
        stop()
        chat?.clear()
    }
}
