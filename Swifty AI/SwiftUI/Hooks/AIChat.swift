import Foundation
import Observation

@MainActor
@Observable
public final class AIChat {
    public var messages: [ChatMessage]
    public var input: String
    public var isLoading: Bool
    public var error: Error?

    private var model: (any AIStreamModel)?
    private let modelString: String?
    private let systemPrompt: String?
    private let maxMessages: Int?
    private let options: GenerationOptions
    private var streamTask: Task<Void, Never>?
    private var streamID = 0

    public init(
        model: any AIStreamModel,
        systemPrompt: String? = nil,
        maxMessages: Int? = nil,
        options: GenerationOptions = GenerationOptions()
    ) {
        self.messages = []
        self.input = ""
        self.isLoading = false
        self.error = nil
        self.model = model
        self.modelString = nil
        self.systemPrompt = systemPrompt
        self.maxMessages = maxMessages
        self.options = options
    }

    public init(
        model modelString: String,
        systemPrompt: String? = nil,
        maxMessages: Int? = nil,
        options: GenerationOptions = GenerationOptions()
    ) {
        self.messages = []
        self.input = ""
        self.isLoading = false
        self.error = nil
        self.model = nil
        self.modelString = modelString
        self.systemPrompt = systemPrompt
        self.maxMessages = maxMessages
        self.options = options
    }

    public func send() {
        guard !isLoading else { return }

        let text = input
        guard !text.isEmpty else { return }

        error = nil
        input = ""
        messages.append(ChatMessage(role: .user, content: text))

        let history = buildHistory()
        messages.append(ChatMessage(role: .assistant, content: ""))
        let assistantIndex = messages.count - 1

        isLoading = true
        streamID += 1
        let currentStreamID = streamID
        streamTask = Task { [weak self] in
            guard let self else { return }
            await self.streamReply(history: history, assistantIndex: assistantIndex, streamID: currentStreamID)
        }
    }

    public func stop() {
        streamID += 1
        streamTask?.cancel()
        streamTask = nil
        isLoading = false
    }

    public func reset() {
        stop()
        messages = []
        input = ""
        error = nil
    }

    private func resolveModel() async throws -> any AIStreamModel {
        if let model {
            return model
        }

        guard let modelString else {
            throw AIError.unsupportedFeature("AIChat has no model configured")
        }

        let resolved = try await AIRegistry.shared.resolve(modelString)
        model = resolved
        return resolved
    }

    private func streamReply(history: [ChatMessage], assistantIndex: Int, streamID: Int) async {
        defer {
            finishStream(streamID)
        }

        do {
            let resolvedModel = try await resolveModel()
            let stream = resolvedModel.stream(messages: history, options: options)

            for try await chunk in stream {
                guard !Task.isCancelled, self.streamID == streamID else { return }
                guard !chunk.text.isEmpty else { continue }
                guard messages.indices.contains(assistantIndex) else { return }
                messages[assistantIndex].content += chunk.text
            }
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled, self.streamID == streamID else { return }
            self.error = error
        }
    }

    private func finishStream(_ streamID: Int) {
        guard self.streamID == streamID else { return }
        streamTask = nil
        isLoading = false
    }

    private func buildHistory() -> [ChatMessage] {
        var history: [ChatMessage] = []

        if let systemPrompt {
            history.append(ChatMessage(role: .system, content: systemPrompt))
        }

        history.append(contentsOf: messages)

        if let maxMessages {
            return pruneMessages(history, maxMessages: maxMessages)
        }

        return history
    }
}
