import Foundation

public struct TelemetryMetadata: Sendable {
    public let requestID: String
    public let callID: String
    public let operation: String
    public let provider: String?
    public let model: String?
    public let name: String?
    public let attributes: [String: String]

    public init(
        requestID: String = generateTelemetryRequestID(),
        callID: String = generateTelemetryCallID(),
        operation: String = "ai.call",
        provider: String? = nil,
        model: String? = nil,
        name: String? = nil,
        attributes: [String: String] = [:]
    ) {
        self.requestID = requestID
        self.callID = callID
        self.operation = operation
        self.provider = provider
        self.model = model
        self.name = name
        self.attributes = attributes
    }

    public func updating(
        provider: String? = nil,
        model: String? = nil,
        name: String? = nil,
        attributes: [String: String] = [:]
    ) -> TelemetryMetadata {
        TelemetryMetadata(
            requestID: requestID,
            callID: callID,
            operation: operation,
            provider: provider ?? self.provider,
            model: model ?? self.model,
            name: name ?? self.name,
            attributes: self.attributes.merging(attributes) { _, new in new }
        )
    }
}

public struct LatencyMetrics: Sendable {
    public let startedAt: Date
    public let firstTokenAt: Date?
    public let finishedAt: Date?

    public var timeToFirstToken: TimeInterval? {
        firstTokenAt?.timeIntervalSince(startedAt)
    }

    public var totalLatency: TimeInterval? {
        finishedAt?.timeIntervalSince(startedAt)
    }

    public var isFinished: Bool {
        finishedAt != nil
    }

    public init(startedAt: Date = .now, firstTokenAt: Date? = nil, finishedAt: Date? = nil) {
        self.startedAt = startedAt
        self.firstTokenAt = firstTokenAt
        self.finishedAt = finishedAt
    }

    public func recordingFirstToken(at date: Date = .now) -> LatencyMetrics {
        LatencyMetrics(startedAt: startedAt, firstTokenAt: firstTokenAt ?? date, finishedAt: finishedAt)
    }

    public func finishing(at date: Date = .now) -> LatencyMetrics {
        LatencyMetrics(startedAt: startedAt, firstTokenAt: firstTokenAt, finishedAt: finishedAt ?? date)
    }
}

public struct AICallTelemetry: Sendable {
    public let metadata: TelemetryMetadata
    public let latency: LatencyMetrics
    public let usage: TokenUsage?
    public let finishReason: String?
    public let errorMessage: String?

    public var succeeded: Bool {
        errorMessage == nil
    }

    public init(
        metadata: TelemetryMetadata,
        latency: LatencyMetrics,
        usage: TokenUsage? = nil,
        finishReason: String? = nil,
        errorMessage: String? = nil
    ) {
        self.metadata = metadata
        self.latency = latency
        self.usage = usage
        self.finishReason = finishReason
        self.errorMessage = errorMessage
    }
}

public protocol TelemetryCollector: Sendable {
    func record(_ telemetry: AICallTelemetry) async
}

public struct NoopTelemetryCollector: TelemetryCollector {
    public static let shared = NoopTelemetryCollector()

    public init() {}

    public func record(_ telemetry: AICallTelemetry) async {}
}

public struct AICallTelemetryRecorder: Sendable {
    public let metadata: TelemetryMetadata
    public let latency: LatencyMetrics

    public init(metadata: TelemetryMetadata = TelemetryMetadata(), startedAt: Date = .now) {
        self.metadata = metadata
        self.latency = LatencyMetrics(startedAt: startedAt)
    }

    public init(metadata: TelemetryMetadata, latency: LatencyMetrics) {
        self.metadata = metadata
        self.latency = latency
    }

    public func recordingFirstToken(at date: Date = .now) -> AICallTelemetryRecorder {
        AICallTelemetryRecorder(metadata: metadata, latency: latency.recordingFirstToken(at: date))
    }

    public func finishing(
        usage: TokenUsage? = nil,
        model: String? = nil,
        finishReason: String? = nil,
        errorMessage: String? = nil,
        at date: Date = .now
    ) -> AICallTelemetry {
        AICallTelemetry(
            metadata: metadata.updating(model: model),
            latency: latency.finishing(at: date),
            usage: usage,
            finishReason: finishReason,
            errorMessage: errorMessage
        )
    }

    public func finishing(response: AIResponse, at date: Date = .now) -> AICallTelemetry {
        finishing(
            usage: response.usage,
            model: response.model,
            finishReason: response.finishReason,
            at: date
        )
    }

    public func failing(_ error: Error, at date: Date = .now) -> AICallTelemetry {
        finishing(errorMessage: error.localizedDescription, at: date)
    }
}

public func generateTelemetryRequestID() -> String {
    generateId(prefix: "req")
}

public func generateTelemetryCallID() -> String {
    generateId(prefix: "call")
}

public func startAICallTelemetry(
    operation: String = "ai.call",
    provider: String? = nil,
    model: String? = nil,
    name: String? = nil,
    attributes: [String: String] = [:],
    at date: Date = .now
) -> AICallTelemetryRecorder {
    AICallTelemetryRecorder(
        metadata: TelemetryMetadata(
            operation: operation,
            provider: provider,
            model: model,
            name: name,
            attributes: attributes
        ),
        startedAt: date
    )
}

public func recordFirstToken(
    _ recorder: AICallTelemetryRecorder,
    at date: Date = .now
) -> AICallTelemetryRecorder {
    recorder.recordingFirstToken(at: date)
}

public func finishAICallTelemetry(
    _ recorder: AICallTelemetryRecorder,
    response: AIResponse,
    at date: Date = .now
) -> AICallTelemetry {
    recorder.finishing(response: response, at: date)
}

public func finishAICallTelemetry(
    _ recorder: AICallTelemetryRecorder,
    usage: TokenUsage? = nil,
    model: String? = nil,
    finishReason: String? = nil,
    at date: Date = .now
) -> AICallTelemetry {
    recorder.finishing(usage: usage, model: model, finishReason: finishReason, at: date)
}

public func failAICallTelemetry(
    _ recorder: AICallTelemetryRecorder,
    error: Error,
    at date: Date = .now
) -> AICallTelemetry {
    recorder.failing(error, at: date)
}
