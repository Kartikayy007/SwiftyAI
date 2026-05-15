import XCTest
import SwiftyAI

final class TelemetryPackageTests: XCTestCase {
    func testTelemetryPublicAPIIsAvailableFromPackageProduct() async {
        let recorder = startAICallTelemetry(operation: "generateText", model: "test-model")
        let telemetry = finishAICallTelemetry(
            recordFirstToken(recorder),
            response: AIResponse(
                text: "ok",
                usage: TokenUsage(inputTokens: 1, outputTokens: 1),
                finishReason: "stop"
            )
        )

        XCTAssertTrue(telemetry.metadata.requestID.hasPrefix("req_"))
        XCTAssertTrue(telemetry.metadata.callID.hasPrefix("call_"))
        XCTAssertEqual(telemetry.metadata.model, "test-model")
        XCTAssertEqual(telemetry.finishReason, "stop")

        await NoopTelemetryCollector().record(telemetry)
    }
}
