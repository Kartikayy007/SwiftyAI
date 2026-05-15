import Foundation
import XCTest
@testable import Swifty_AI

final class StreamingUtilitiesTests: XCTestCase {
    func testSimulateReadableStreamSplitsTextInOrder() async throws {
        let chunks = try await collect(simulateReadableStream("Hello world", chunkSize: 3))

        XCTAssertEqual(chunks, ["Hel", "lo ", "wor", "ld"])
    }

    func testSimulateReadableStreamEmitsArrayChunksInOrder() async throws {
        let chunks = try await collect(simulateReadableStream(["Hel", "lo", " world"]))

        XCTAssertEqual(chunks, ["Hel", "lo", " world"])
    }

    func testSimulateReadableStreamSupportsDelay() async throws {
        let start = Date()
        _ = try await collect(simulateReadableStream(["a", "b"], delay: .milliseconds(10)))

        XCTAssertGreaterThanOrEqual(Date().timeIntervalSince(start), 0.01)
    }

    func testSimulateReadableStreamSupportsCancellation() async throws {
        let stream = simulateReadableStream((0..<100).map(String.init), delay: .milliseconds(10))
        let task = Task {
            try await collect(stream)
        }

        try await Task.sleep(for: .milliseconds(25))
        task.cancel()

        let chunks = try await task.value
        XCTAssertLessThan(chunks.count, 100)
    }

    func testSmoothStreamControlsChunkSize() async throws {
        let raw = simulateReadableStream(["He", "llo wor", "ld"])
        let smooth = smoothStream(raw, charactersPerChunk: 4, interval: .milliseconds(0))

        let chunks = try await collect(smooth)

        XCTAssertEqual(chunks, ["Hell", "o wo", "rld"])
    }

    func testSmoothStreamPreservesFinalText() async throws {
        let raw = simulateReadableStream(["S", "tream", "ing", " text"])
        let smooth = smoothStream(raw, charactersPerChunk: 3, interval: .milliseconds(0))

        let chunks = try await collect(smooth)

        XCTAssertEqual(chunks.joined(), "Streaming text")
    }

    func testSmoothStreamSupportsCancellation() async throws {
        let raw = simulateReadableStream((0..<100).map { "\($0)" }, delay: .milliseconds(5))
        let smooth = smoothStream(raw, charactersPerChunk: 1, interval: .milliseconds(5))
        let task = Task {
            try await collect(smooth)
        }

        try await Task.sleep(for: .milliseconds(25))
        task.cancel()

        let chunks = try await task.value
        XCTAssertLessThan(chunks.count, 100)
    }

    private func collect(_ stream: AsyncThrowingStream<String, Error>) async throws -> [String] {
        var chunks: [String] = []

        for try await chunk in stream {
            chunks.append(chunk)
        }

        return chunks
    }
}
