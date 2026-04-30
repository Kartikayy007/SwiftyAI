import Foundation
import SwiftyAI

enum ExampleState<Value> {
    case idle
    case loading
    case success(Value)
    case failure(String)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}

struct ExampleError: LocalizedError {
    let message: String

    var errorDescription: String? { message }

    static func message(_ value: String) -> ExampleError {
        ExampleError(message: value)
    }
}

extension Error {
    var exampleMessage: String {
        if let localized = (self as? LocalizedError)?.errorDescription, !localized.isEmpty {
            return localized
        }
        return localizedDescription
    }
}

extension TokenUsage {
    var summary: String {
        let total = totalTokens.map { "total \($0)" } ?? "total unknown"
        let cached = cachedInputTokens.map { ", cached \($0)" } ?? ""
        return "input \(inputTokens), output \(outputTokens), \(total)\(cached)"
    }
}
