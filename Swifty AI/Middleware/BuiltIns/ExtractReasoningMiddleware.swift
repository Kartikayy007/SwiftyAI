public func extractReasoningMiddleware(
    tags: [String] = ["thinking"]
) -> LanguageModelMiddleware {
    LanguageModelMiddleware { request, next in
        let response = try await next(request)
        return AIResponse(
            text: ReasoningTagStripper.strip(response.text, tags: tags),
            model: response.model,
            usage: response.usage,
            finishReason: response.finishReason
        )
    }
}
