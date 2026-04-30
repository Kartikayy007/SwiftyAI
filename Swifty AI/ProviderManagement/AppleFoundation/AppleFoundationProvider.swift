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
        let formatted = messages.map { msg in
            switch msg.role {
            case .system: return "System: \(msg.content)"
            case .user: return "User: \(msg.content)"
            case .assistant: return "Assistant: \(msg.content)"
            }
        }.joined(separator: "\n")
        return stream(formatted)
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
