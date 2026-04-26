import Foundation

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26, macOS 26, *)
public struct AppleFoundationProvider: AIModel {
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
}
#endif
