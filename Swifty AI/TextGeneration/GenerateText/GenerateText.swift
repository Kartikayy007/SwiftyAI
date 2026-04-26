public func generateText(model: some AIModel, prompt: String) async throws -> AIResponse {
    try await model.generate(prompt)
}

public func generateText(model: String, prompt: String) async throws -> AIResponse {
    let resolved = try await AIRegistry.shared.resolve(model)
    return try await generateText(model: resolved, prompt: prompt)
}
