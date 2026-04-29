public enum JSONExtractionFailureBehavior: Sendable {
    case leaveUnchanged
    case throwError
}

public func extractJsonMiddleware(
    onFailure: JSONExtractionFailureBehavior = .leaveUnchanged
) -> LanguageModelMiddleware {
    LanguageModelMiddleware { request, next in
        let response = try await next(request)
        guard let json = JSONExtraction.extract(from: response.text) else {
            switch onFailure {
            case .leaveUnchanged:
                return response
            case .throwError:
                throw AIError.invalidResponse
            }
        }
        return AIResponse(
            text: json,
            model: response.model,
            usage: response.usage,
            finishReason: response.finishReason
        )
    }
}
