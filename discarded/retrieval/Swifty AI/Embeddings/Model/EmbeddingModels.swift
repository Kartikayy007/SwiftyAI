public enum EmbeddingTaskType: String, Sendable, Codable, Equatable {
    case retrievalQuery = "RETRIEVAL_QUERY"
    case retrievalDocument = "RETRIEVAL_DOCUMENT"
    case semanticSimilarity = "SEMANTIC_SIMILARITY"
    case classification = "CLASSIFICATION"
    case clustering = "CLUSTERING"
    case questionAnswering = "QUESTION_ANSWERING"
    case factVerification = "FACT_VERIFICATION"
    case codeRetrievalQuery = "CODE_RETRIEVAL_QUERY"
}

public struct EmbeddingOptions: Sendable {
    public var dimensions: Int?
    public var taskType: EmbeddingTaskType?
    public var title: String?
    public var headers: [String: String]
    public var retryPolicy: RetryPolicy

    public init(
        dimensions: Int? = nil,
        taskType: EmbeddingTaskType? = nil,
        title: String? = nil,
        headers: [String: String] = [:],
        retryPolicy: RetryPolicy = .none
    ) {
        self.dimensions = dimensions
        self.taskType = taskType
        self.title = title
        self.headers = headers
        self.retryPolicy = retryPolicy
    }

    var generationOptions: GenerationOptions {
        GenerationOptions(headers: headers, retryPolicy: retryPolicy)
    }
}

public struct EmbeddingUsage: Sendable {
    public let inputTokens: Int
    public let totalTokens: Int?

    public init(inputTokens: Int, totalTokens: Int? = nil) {
        self.inputTokens = inputTokens
        self.totalTokens = totalTokens
    }
}

public struct EmbeddingResponse: Sendable {
    public let embeddings: [[Double]]
    public let model: String?
    public let usage: EmbeddingUsage?

    public init(
        embeddings: [[Double]],
        model: String? = nil,
        usage: EmbeddingUsage? = nil
    ) {
        self.embeddings = embeddings
        self.model = model
        self.usage = usage
    }

    public var embedding: [Double]? {
        embeddings.first
    }
}
