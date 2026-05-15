extension AIRegistry {
    func resolveEmbeddingModel(_ modelString: String) throws -> any AIEmbeddingModel {
        let resolved = try resolve(modelString)
        guard let model = resolved as? any AIEmbeddingModel else {
            throw AIError.unsupportedFeature("Embeddings are not supported by \(modelString)")
        }
        return model
    }
}
