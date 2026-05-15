public func embed(
    model: some AIEmbeddingModel,
    input: String,
    options: EmbeddingOptions = EmbeddingOptions()
) async throws -> EmbeddingResponse {
    try await model.embed(input, options: options)
}

public func embed(
    model: String,
    input: String,
    options: EmbeddingOptions = EmbeddingOptions()
) async throws -> EmbeddingResponse {
    let resolved = try await AIRegistry.shared.resolveEmbeddingModel(model)
    return try await embed(model: resolved, input: input, options: options)
}

public func embedMany(
    model: some AIEmbeddingModel,
    inputs: [String],
    options: EmbeddingOptions = EmbeddingOptions()
) async throws -> EmbeddingResponse {
    try await model.embedMany(inputs, options: options)
}

public func embedMany(
    model: String,
    inputs: [String],
    options: EmbeddingOptions = EmbeddingOptions()
) async throws -> EmbeddingResponse {
    let resolved = try await AIRegistry.shared.resolveEmbeddingModel(model)
    return try await embedMany(model: resolved, inputs: inputs, options: options)
}
