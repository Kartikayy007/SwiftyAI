public func generateText(model: some AIModel, prompt: String) async throws -> AIResponse {
    try await model.generate(prompt)
}
