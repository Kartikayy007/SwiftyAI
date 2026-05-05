public func rerank(
    model: some AIRerankModel,
    query: String,
    documents: [RerankDocument],
    options: RerankOptions = RerankOptions()
) async throws -> RerankResponse {
    try await model.rerank(query: query, documents: documents, options: options)
}

public func rerank(
    model: some AIRerankModel,
    query: String,
    documents: [String],
    options: RerankOptions = RerankOptions()
) async throws -> RerankResponse {
    try await model.rerank(query: query, documents: documents, options: options)
}

public func rerank(
    model: String,
    query: String,
    documents: [RerankDocument],
    options: RerankOptions = RerankOptions()
) async throws -> RerankResponse {
    let resolved = try await AIRegistry.shared.resolveRerankModel(model)
    return try await resolved.rerank(query: query, documents: documents, options: options)
}

public func rerank(
    model: String,
    query: String,
    documents: [String],
    options: RerankOptions = RerankOptions()
) async throws -> RerankResponse {
    let resolved = try await AIRegistry.shared.resolveRerankModel(model)
    return try await resolved.rerank(
        query: query,
        documents: documents.map { RerankDocument($0) },
        options: options
    )
}
