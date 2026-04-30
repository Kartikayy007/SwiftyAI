extension AIRegistry {
    func resolveRerankModel(_ modelString: String) throws -> any AIRerankModel {
        let parts = modelString.split(separator: "/", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { throw AIError.invalidModelString(modelString) }

        let provider = parts[0].lowercased()
        switch provider {
        case "cohere":
            guard let cohere = try resolve(modelString) as? OpenAICompatibleProvider else {
                throw AIError.unsupportedFeature("Reranking is not supported by \(modelString)")
            }
            return CohereRerankProvider(apiKey: cohere.apiKey, model: cohere.model)
        default:
            throw AIError.unsupportedFeature("Reranking is not supported for provider '\(provider)'")
        }
    }
}
