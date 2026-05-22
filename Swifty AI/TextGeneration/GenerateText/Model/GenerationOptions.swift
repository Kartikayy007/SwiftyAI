import Foundation

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
    public var promptCaching: PromptCachingOptions?

    private var _retryPolicy: RetryPolicy
    internal var wasRetryPolicySet: Bool

    public var retryPolicy: RetryPolicy {
        get { _retryPolicy }
        set {
            _retryPolicy = newValue
            wasRetryPolicySet = true
        }
    }

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
        self._retryPolicy = retryPolicy
        // Flag is true iff the caller passed something other than the default.
        // We can't observe default-vs-explicit at this layer; treat any non-.none value as explicit,
        // plus expose `setRetryPolicy(_:)` for tests / middleware that want to force the flag.
        self.wasRetryPolicySet = retryPolicy.maxAttempts != RetryPolicy.none.maxAttempts
            || retryPolicy.retryableStatusCodes != RetryPolicy.none.retryableStatusCodes
        self.promptCaching = promptCaching
    }
}

public struct RetryPolicy: Sendable {
    public let maxAttempts: Int
    public let baseDelay: Duration
    public let maxDelay: Duration
    public let jitter: Double
    public let retryableStatusCodes: Set<Int>

    public static let none = RetryPolicy(maxAttempts: 1)

    public init(
        maxAttempts: Int,
        baseDelay: Duration = .milliseconds(250),
        maxDelay: Duration = .seconds(30),
        jitter: Double = 0,
        retryableStatusCodes: Set<Int> = [408, 409, 425, 429, 500, 502, 503, 504]
    ) {
        self.maxAttempts = max(1, maxAttempts)
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.jitter = min(max(jitter, 0), 1)
        self.retryableStatusCodes = retryableStatusCodes
    }

    /// Delay before the next attempt. `attempt` is 1-indexed (1 = first retry, after attempt 1 failed).
    /// Schedule: baseDelay, baseDelay*2, baseDelay*4, ..., capped at maxDelay. Optional ± jitter * delay.
    public func delay(forAttempt attempt: Int) -> Duration {
        let n = max(1, attempt)
        let scale = pow(2.0, Double(n - 1))
        let baseSeconds = Self.seconds(of: baseDelay)
        let capSeconds = Self.seconds(of: maxDelay)
        var seconds = min(capSeconds, baseSeconds * scale)
        if jitter > 0 {
            let spread = seconds * jitter
            seconds += Double.random(in: -spread...spread)
            seconds = max(0, seconds)
        }
        return .seconds(seconds)
    }

    private static func seconds(of duration: Duration) -> Double {
        let components = duration.components
        return Double(components.seconds) + Double(components.attoseconds) / 1e18
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
