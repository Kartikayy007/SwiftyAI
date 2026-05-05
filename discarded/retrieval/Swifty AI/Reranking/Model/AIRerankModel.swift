public protocol AIRerankModel: Sendable {
    func rerank(
        query: String,
        documents: [RerankDocument],
        options: RerankOptions
    ) async throws -> RerankResponse
}

public extension AIRerankModel {
    func rerank(
        query: String,
        documents: [String],
        options: RerankOptions = RerankOptions()
    ) async throws -> RerankResponse {
        try await rerank(
            query: query,
            documents: documents.map { RerankDocument($0) },
            options: options
        )
    }
}
