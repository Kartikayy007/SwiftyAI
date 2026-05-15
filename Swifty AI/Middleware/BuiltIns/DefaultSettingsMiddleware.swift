public struct DefaultLanguageModelSettings: Sendable {
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
    public var retryPolicy: RetryPolicy?
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
        retryPolicy: RetryPolicy? = nil,
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

public func defaultSettingsMiddleware(
    _ settings: DefaultLanguageModelSettings
) -> LanguageModelMiddleware {
    LanguageModelMiddleware { request, next in
        var request = request
        request.options.applyDefaults(settings)
        return try await next(request)
    }
}

public func defaultSettingsMiddleware(
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
    retryPolicy: RetryPolicy? = nil,
    promptCaching: PromptCachingOptions? = nil
) -> LanguageModelMiddleware {
    defaultSettingsMiddleware(
        DefaultLanguageModelSettings(
            system: system,
            temperature: temperature,
            topP: topP,
            topK: topK,
            maxTokens: maxTokens,
            seed: seed,
            presencePenalty: presencePenalty,
            frequencyPenalty: frequencyPenalty,
            stopSequences: stopSequences,
            headers: headers,
            retryPolicy: retryPolicy,
            promptCaching: promptCaching
        )
    )
}

public func defaultStreamingSettingsMiddleware(
    _ settings: DefaultLanguageModelSettings
) -> LanguageModelStreamMiddleware {
    LanguageModelStreamMiddleware { request, next in
        var request = request
        request.options.applyDefaults(settings)
        return next.stream(request)
    }
}

public func defaultStreamingSettingsMiddleware(
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
    retryPolicy: RetryPolicy? = nil,
    promptCaching: PromptCachingOptions? = nil
) -> LanguageModelStreamMiddleware {
    defaultStreamingSettingsMiddleware(
        DefaultLanguageModelSettings(
            system: system,
            temperature: temperature,
            topP: topP,
            topK: topK,
            maxTokens: maxTokens,
            seed: seed,
            presencePenalty: presencePenalty,
            frequencyPenalty: frequencyPenalty,
            stopSequences: stopSequences,
            headers: headers,
            retryPolicy: retryPolicy,
            promptCaching: promptCaching
        )
    )
}

extension GenerationOptions {
    mutating func applyDefaults(_ settings: DefaultLanguageModelSettings) {
        system = system ?? settings.system
        temperature = temperature ?? settings.temperature
        topP = topP ?? settings.topP
        topK = topK ?? settings.topK
        maxTokens = maxTokens ?? settings.maxTokens
        seed = seed ?? settings.seed
        presencePenalty = presencePenalty ?? settings.presencePenalty
        frequencyPenalty = frequencyPenalty ?? settings.frequencyPenalty
        stopSequences = stopSequences ?? settings.stopSequences
        promptCaching = promptCaching ?? settings.promptCaching

        for (key, value) in settings.headers where headers[key] == nil {
            headers[key] = value
        }

        if let retryPolicy = settings.retryPolicy, isRetryPolicyUnset {
            self.retryPolicy = retryPolicy
        }
    }

    private var isRetryPolicyUnset: Bool {
        retryPolicy.maxAttempts == RetryPolicy.none.maxAttempts
            && retryPolicy.retryableStatusCodes == RetryPolicy.none.retryableStatusCodes
    }
}
