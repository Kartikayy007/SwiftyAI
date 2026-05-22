import Foundation

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26, macOS 26, *)
public struct AppleFoundationProvider: AIModel, AIStreamModel, AIToolCallingModel {
    private let session: LanguageModelSession

    public init() {
        self.session = LanguageModelSession()
    }

    public static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    public func generate(_ prompt: String) async throws -> AIResponse {
        do {
            let response = try await session.respond(to: prompt)
            return AIResponse(text: response.content, model: "apple-on-device", usage: nil, finishReason: nil)
        } catch {
            throw AIError.networkError(error)
        }
    }

    public func stream(messages: [ChatMessage]) -> AsyncThrowingStream<AIStreamChunk, Error> {
        stream(messages: messages, options: GenerationOptions())
    }

    /// Note: Apple's `LanguageModelSession.streamResponse(to:)` does not currently surface
    /// per-request controls (temperature, maxTokens, etc.), so `options` is ignored here
    /// except for `options.system`, which is prepended to the formatted prompt when set.
    public func stream(messages: [ChatMessage], options: GenerationOptions) -> AsyncThrowingStream<AIStreamChunk, Error> {
        var lines = [String]()
        if let system = options.system {
            lines.append("System: \(system)")
        }
        for msg in messages {
            switch msg.role {
            case .system: lines.append("System: \(msg.content)")
            case .user: lines.append("User: \(msg.content)")
            case .assistant: lines.append("Assistant: \(msg.content)")
            }
        }
        return stream(lines.joined(separator: "\n"))
    }

    public func stream(_ prompt: String) -> AsyncThrowingStream<AIStreamChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                var previousContent = ""
                do {
                    let responseStream = session.streamResponse(to: prompt)
                    for try await partial in responseStream {
                        if Task.isCancelled {
                            continuation.finish()
                            return
                        }
                        let current = partial.content
                        let delta = String(current.dropFirst(previousContent.count))
                        previousContent = current
                        if !delta.isEmpty {
                            continuation.yield(AIStreamChunk(text: delta, finishReason: nil, usage: nil))
                        }
                    }
                    continuation.yield(AIStreamChunk(text: "", finishReason: "stop", usage: nil))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: AIError.networkError(error))
                }
            }
        }
    }
}
#endif
