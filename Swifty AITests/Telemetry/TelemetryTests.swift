import Foundation
import XCTest
@testable import Swifty_AI

final class TelemetryTests: XCTestCase {
    func testTelemetryIDHelpersUseExpectedPrefixes() {
        let requestID = generateTelemetryRequestID()
        let callID = generateTelemetryCallID()

        XCTAssertTrue(requestID.hasPrefix("req_"))
        XCTAssertTrue(callID.hasPrefix("call_"))
        XCTAssertNotNil(UUID(uuidString: String(requestID.dropFirst("req_".count))))
        XCTAssertNotNil(UUID(uuidString: String(callID.dropFirst("call_".count))))
    }

    func testLatencyMetricsRecordFirstTokenAndFinish() {
        let startedAt = Date(timeIntervalSince1970: 10)
        let firstTokenAt = Date(timeIntervalSince1970: 11.25)
        let finishedAt = Date(timeIntervalSince1970: 13.5)

        let latency = LatencyMetrics(startedAt: startedAt)
            .recordingFirstToken(at: firstTokenAt)
            .finishing(at: finishedAt)

        XCTAssertEqual(latency.timeToFirstToken ?? -1, 1.25, accuracy: 0.001)
        XCTAssertEqual(latency.totalLatency ?? -1, 3.5, accuracy: 0.001)
        XCTAssertTrue(latency.isFinished)
    }

    func testRecorderBuildsFinishedTelemetryFromResponse() {
        let startedAt = Date(timeIntervalSince1970: 100)
        let firstTokenAt = Date(timeIntervalSince1970: 101)
        let finishedAt = Date(timeIntervalSince1970: 103)
        let recorder = startAICallTelemetry(
            operation: "generateText",
            provider: "openai",
            name: "summary",
            attributes: ["screen": "compose"],
            at: startedAt
        )
        let response = AIResponse(
            text: "Done",
            model: "gpt-4o-mini",
            usage: TokenUsage(inputTokens: 4, outputTokens: 2, totalTokens: 6),
            finishReason: "stop"
        )

        let telemetry = finishAICallTelemetry(
            recordFirstToken(recorder, at: firstTokenAt),
            response: response,
            at: finishedAt
        )

        XCTAssertEqual(telemetry.metadata.operation, "generateText")
        XCTAssertEqual(telemetry.metadata.provider, "openai")
        XCTAssertEqual(telemetry.metadata.model, "gpt-4o-mini")
        XCTAssertEqual(telemetry.metadata.name, "summary")
        XCTAssertEqual(telemetry.metadata.attributes["screen"], "compose")
        XCTAssertEqual(telemetry.usage?.inputTokens, 4)
        XCTAssertEqual(telemetry.finishReason, "stop")
        XCTAssertNil(telemetry.errorMessage)
        XCTAssertTrue(telemetry.succeeded)
        XCTAssertEqual(telemetry.latency.timeToFirstToken ?? -1, 1, accuracy: 0.001)
        XCTAssertEqual(telemetry.latency.totalLatency ?? -1, 3, accuracy: 0.001)
    }

    func testFailureTelemetryRecordsErrorMessageAndLatency() {
        let recorder = startAICallTelemetry(at: Date(timeIntervalSince1970: 0))

        let telemetry = failAICallTelemetry(
            recorder,
            error: SampleError(message: "network down"),
            at: Date(timeIntervalSince1970: 2)
        )

        XCTAssertEqual(telemetry.errorMessage, "network down")
        XCTAssertFalse(telemetry.succeeded)
        XCTAssertEqual(telemetry.latency.totalLatency ?? -1, 2, accuracy: 0.001)
    }

    func testNoopCollectorAcceptsTelemetry() async {
        let telemetry = finishAICallTelemetry(
            startAICallTelemetry(),
            response: AIResponse(text: "ok")
        )

        await NoopTelemetryCollector.shared.record(telemetry)
    }
}

private struct SampleError: LocalizedError {
    let message: String

    var errorDescription: String? {
        message
    }
}
