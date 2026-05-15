public func generateText(
    model: some AIModel,
    prompt: String,
    options: GenerationOptions = GenerationOptions()
) async throws -> AIResponse {
    try await model.generate(prompt, options: options)
}

public func generateText(
    model: some AIModel,
    prompt: [AIMessageContent],
    options: GenerationOptions = GenerationOptions()
) async throws -> AIResponse {
    try await model.generate(prompt, options: options)
}

public func generateText(
    model: String,
    prompt: String,
    options: GenerationOptions = GenerationOptions()
) async throws -> AIResponse {
    let resolved = try await AIRegistry.shared.resolve(model)
    return try await generateText(model: resolved, prompt: prompt, options: options)
}

public func generateText(
    model: String,
    prompt: [AIMessageContent],
    options: GenerationOptions = GenerationOptions()
) async throws -> AIResponse {
    let resolved = try await AIRegistry.shared.resolve(model)
    return try await generateText(model: resolved, prompt: prompt, options: options)
}
