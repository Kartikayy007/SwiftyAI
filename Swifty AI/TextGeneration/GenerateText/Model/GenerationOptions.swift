public struct GenerationOptions: Sendable {
    public var system: String?
    public var temperature: Double?
    public var topP: Double?
    public var topK: Int?
    public var maxTokens: Int?
    public var seed: Int?
    public var presencePenalty: Double?
    public var frequencyPenalty: Double?
    public var stopSequences: [String]?
    public var headers: [String: String]
    public var retryPolicy: RetryPolicy
    public var promptCaching: PromptCachingOptions?

    public init(
        system: String? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        topK: Int? = nil,
        maxTokens: Int? = nil,
        seed: Int? = nil,
        presencePenalty: Double? = nil,
        frequencyPenalty: Double? = nil,
        stopSequences: [String]? = nil,
        headers: [String: String] = [:],
        retryPolicy: RetryPolicy = .none,
        promptCaching: PromptCachingOptions? = nil
    ) {
        self.system = system
        self.temperature = temperature
        self.topP = topP
        self.topK = topK
        self.maxTokens = maxTokens
        self.seed = seed
        self.presencePenalty = presencePenalty
        self.frequencyPenalty = frequencyPenalty
        self.stopSequences = stopSequences
        self.headers = headers
        self.retryPolicy = retryPolicy
        self.promptCaching = promptCaching
    }
}

public struct RetryPolicy: Sendable {
    public let maxAttempts: Int
    public let baseDelay: Duration
    public let retryableStatusCodes: Set<Int>

    public static let none = RetryPolicy(maxAttempts: 1)

    public init(
        maxAttempts: Int,
        baseDelay: Duration = .milliseconds(250),
        retryableStatusCodes: Set<Int> = [408, 409, 425, 429, 500, 502, 503, 504]
    ) {
        self.maxAttempts = max(1, maxAttempts)
        self.baseDelay = baseDelay
        self.retryableStatusCodes = retryableStatusCodes
    }
}

public struct PromptCachingOptions: Sendable {
    public let cacheKey: String?
    public let retention: String?
    public let cachedContent: String?

    public init(cacheKey: String? = nil, retention: String? = nil, cachedContent: String? = nil) {
        self.cacheKey = cacheKey
        self.retention = retention
        self.cachedContent = cachedContent
    }
}
