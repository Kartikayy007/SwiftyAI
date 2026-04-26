import XCTest
@testable import Swifty_AI

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26, macOS 26, *)
final class AppleFoundationStreamTests: XCTestCase {
    func testConformsToAIStreamModel() throws {
        guard AppleFoundationProvider.isAvailable else {
            throw XCTSkip("Apple Intelligence not available on this device.")
        }
        let provider: any AIStreamModel = AppleFoundationProvider()
        XCTAssertNotNil(provider)
    }

    func testLiveStream() async throws {
        guard AppleFoundationProvider.isAvailable else {
            throw XCTSkip("Apple Intelligence not available on this device.")
        }
        let provider = AppleFoundationProvider()
        var full = ""
        var lastChunk: AIStreamChunk?
        var chunkCount = 0
        print("[Apple stream] starting...")
        for try await chunk in provider.stream("Reply with exactly: ok") {
            full += chunk.text
            chunkCount += 1
            print("[Apple chunk \(chunkCount)] \"\(chunk.text)\"")
            lastChunk = chunk
        }
        print("[Apple stream] done — \(chunkCount) chunks, full response: \"\(full)\"")
        if let reason = lastChunk?.finishReason { print("[Apple stream] finish reason: \(reason)") }
        if let usage = lastChunk?.usage { print("[Apple stream] tokens — in: \(usage.inputTokens), out: \(usage.outputTokens)") }
        XCTAssertFalse(full.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
#endif
