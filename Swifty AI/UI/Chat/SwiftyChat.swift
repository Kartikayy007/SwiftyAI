import Foundation
import Observation

@Observable
public final class SwiftyChat {
    public var messages: [ChatMessage] = []
    public var isStreaming: Bool = false
    public var error: Error? = nil

    private let model: any AIStreamModel
    private let systemPrompt: String?
    private let maxMessages: Int?
    private var streamTask: Task<Void, Never>?

    public init(model: any AIStreamModel, systemPrompt: String? = nil, maxMessages: Int? = nil) {
        self.model = model
        self.systemPrompt = systemPrompt
        self.maxMessages = maxMessages
    }

    public func send(_ text: String) async throws {
        guard !isStreaming else { return }

        error = nil
        messages.append(ChatMessage(role: .user, content: text))

        let history = buildHistory()

        isStreaming = true
        messages.append(ChatMessage(role: .assistant, content: ""))
        let assistantIndex = messages.count - 1

        let stream = model.stream(messages: history)

        do {
            for try await chunk in stream {
                if Task.isCancelled { break }
                if !chunk.text.isEmpty {
                    messages[assistantIndex].content += chunk.text
                }
            }
        } catch {
            self.error = error
        }

        isStreaming = false
    }

    public func stop() {
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
    }

    public func clear() {
        stop()
        messages = []
        error = nil
    }

    private func buildHistory() -> [ChatMessage] {
        var history: [ChatMessage] = []

        if let system = systemPrompt {
            history.append(ChatMessage(role: .system, content: system))
        }

        let conversationMessages: [ChatMessage]
        if let limit = maxMessages {
            conversationMessages = Array(messages.suffix(limit))
        } else {
            conversationMessages = messages
        }

        history.append(contentsOf: conversationMessages)
        return history
    }
}
