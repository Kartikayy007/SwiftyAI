import XCTest
@testable import Swifty_AI

final class LanguageModelMiddlewareTests: XCTestCase {
    func testWrapLanguageModelComposesRequestAndResponseMiddlewareInOrder() async throws {
        let model = CapturingLanguageModel(response: AIResponse(text: "provider"))
        let wrapped = wrapLanguageModel(
            model,
            middleware: [
                LanguageModelMiddleware { request, next in
                    var request = request
                    request.promptText += " first"
                    let response = try await next(request)
                    return AIResponse(text: response.text + " after-first")
                },
                LanguageModelMiddleware { request, next in
                    var request = request
                    request.promptText += " second"
                    let response = try await next(request)
                    return AIResponse(text: response.text + " after-second")
                },
            ]
        )

        let response = try await generateText(model: wrapped, prompt: "base")

        XCTAssertEqual(model.capturedPrompt, "base first second")
        XCTAssertEqual(response.text, "provider after-second after-first")
    }

    func testDefaultSettingsDoNotOverwriteRequestOptions() async throws {
        let model = CapturingLanguageModel(response: AIResponse(text: "ok"))
        let wrapped = wrapLanguageModel(
            model,
            middleware: [
                defaultSettingsMiddleware(
                    system: "default system",
                    temperature: 0.2,
                    maxTokens: 100,
                    headers: ["X-Trace": "default", "X-Default": "yes"]
                )
            ]
        )

        _ = try await generateText(
            model: wrapped,
            prompt: "Hello",
            options: GenerationOptions(
                system: "request system",
                temperature: 0.9,
                headers: ["X-Trace": "request"]
            )
        )

        XCTAssertEqual(model.capturedOptions?.system, "request system")
        XCTAssertEqual(model.capturedOptions?.temperature, 0.9)
        XCTAssertEqual(model.capturedOptions?.maxTokens, 100)
        XCTAssertEqual(model.capturedOptions?.headers["X-Trace"], "request")
        XCTAssertEqual(model.capturedOptions?.headers["X-Default"], "yes")
    }

    func testExtractJsonMiddlewareExtractsFencedJSON() async throws {
        let model = CapturingLanguageModel(
            response: AIResponse(text: "Here is the JSON:\n```json\n{\"name\":\"A\"}\n```\nDone")
        )
        let wrapped = wrapLanguageModel(model, middleware: [extractJsonMiddleware()])

        let response = try await generateText(model: wrapped, prompt: "json")

        XCTAssertEqual(response.text, "{\"name\":\"A\"}")
    }

    func testExtractJsonMiddlewareExtractsBalancedJSONFromProse() async throws {
        let model = CapturingLanguageModel(
            response: AIResponse(text: "prefix {\"items\":[{\"name\":\"A\"}],\"ok\":true} suffix")
        )
        let wrapped = wrapLanguageModel(model, middleware: [extractJsonMiddleware()])

        let response = try await generateText(model: wrapped, prompt: "json")

        XCTAssertEqual(response.text, "{\"items\":[{\"name\":\"A\"}],\"ok\":true}")
    }

    func testExtractJsonMiddlewareCanLeaveInvalidJSONUnchanged() async throws {
        let model = CapturingLanguageModel(response: AIResponse(text: "not json"))
        let wrapped = wrapLanguageModel(model, middleware: [extractJsonMiddleware()])

        let response = try await generateText(model: wrapped, prompt: "json")

        XCTAssertEqual(response.text, "not json")
    }

    func testExtractJsonMiddlewareCanThrowOnInvalidJSON() async {
        let model = CapturingLanguageModel(response: AIResponse(text: "not json"))
        let wrapped = wrapLanguageModel(model, middleware: [extractJsonMiddleware(onFailure: .throwError)])

        do {
            _ = try await generateText(model: wrapped, prompt: "json")
            XCTFail("Expected invalid response")
        } catch AIError.invalidResponse {
            // pass
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    func testExtractReasoningMiddlewareStripsDefaultAndCustomTags() async throws {
        let model = CapturingLanguageModel(
            response: AIResponse(text: "<thinking>hidden</thinking>\n<scratchpad>also hidden</scratchpad>\nFinal answer")
        )
        let wrapped = wrapLanguageModel(
            model,
            middleware: [extractReasoningMiddleware(tags: ["thinking", "scratchpad"])]
        )

        let response = try await generateText(model: wrapped, prompt: "answer")

        XCTAssertEqual(response.text, "Final answer")
    }

    func testMiddlewareErrorsPropagate() async {
        let model = CapturingLanguageModel(response: AIResponse(text: "ok"))
        let wrapped = wrapLanguageModel(
            model,
            middleware: [
                LanguageModelMiddleware { _, _ in
                    throw AIError.unsupportedFeature("blocked")
                }
            ]
        )

        do {
            _ = try await generateText(model: wrapped, prompt: "Hello")
            XCTFail("Expected unsupportedFeature")
        } catch AIError.unsupportedFeature(let message) {
            XCTAssertEqual(message, "blocked")
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    func testSimulateStreamingMiddlewareChunksGeneratedTextAndPreservesMetadata() async throws {
        let usage = TokenUsage(inputTokens: 1, outputTokens: 2, totalTokens: 3)
        let model = CapturingLanguageModel(
            response: AIResponse(text: "abcdef", model: "mock", usage: usage, finishReason: "stop")
        )
        let wrapped = wrapLanguageModel(
            model,
            streamMiddleware: [simulateStreamingMiddleware(chunkSize: 2)]
        )

        var text = ""
        var lastChunk: AIStreamChunk?
        for try await chunk in streamText(model: wrapped, prompt: "Hello") {
            text += chunk.text
            lastChunk = chunk
        }

        XCTAssertEqual(text, "abcdef")
        XCTAssertEqual(lastChunk?.finishReason, "stop")
        XCTAssertEqual(lastChunk?.usage?.totalTokens, 3)
    }

    func testStreamingSettingsMiddlewareAppliesDefaultsWithoutOverwritingRequestOptions() async throws {
        let model = CapturingStreamModel()
        let wrapped = wrapStreamingLanguageModel(
            model,
            streamMiddleware: [
                defaultStreamingSettingsMiddleware(
                    temperature: 0.2,
                    maxTokens: 100,
                    headers: ["X-Trace": "default", "X-Default": "yes"]
                )
            ]
        )

        for try await _ in streamText(
            model: wrapped,
            prompt: "Hello",
            options: GenerationOptions(temperature: 0.8, headers: ["X-Trace": "request"])
        ) {}

        XCTAssertEqual(model.capturedOptions?.temperature, 0.8)
        XCTAssertEqual(model.capturedOptions?.maxTokens, 100)
        XCTAssertEqual(model.capturedOptions?.headers["X-Trace"], "request")
        XCTAssertEqual(model.capturedOptions?.headers["X-Default"], "yes")
    }
}

private final class CapturingLanguageModel: AIModel, @unchecked Sendable {
    private let response: AIResponse
    private let error: Error?
    private(set) var capturedPrompt: String?
    private(set) var capturedOptions: GenerationOptions?

    init(response: AIResponse, error: Error? = nil) {
        self.response = response
        self.error = error
    }

    func generate(_ prompt: String) async throws -> AIResponse {
        try await generate(prompt, options: GenerationOptions())
    }

    func generate(_ prompt: String, options: GenerationOptions) async throws -> AIResponse {
        capturedPrompt = prompt
        capturedOptions = options
        if let error { throw error }
        return response
    }

    func generate(_ prompt: [AIMessageContent], options: GenerationOptions) async throws -> AIResponse {
        capturedPrompt = prompt.textContent
        capturedOptions = options
        if let error { throw error }
        return response
    }
}

private final class CapturingStreamModel: AIStreamModel, @unchecked Sendable {
    private(set) var capturedOptions: GenerationOptions?

    func generate(_ prompt: String) async throws -> AIResponse {
        AIResponse(text: "generated")
    }

    func stream(_ prompt: String) -> AsyncThrowingStream<AIStreamChunk, Error> {
        stream(prompt, options: GenerationOptions())
    }

    func stream(_ prompt: String, options: GenerationOptions) -> AsyncThrowingStream<AIStreamChunk, Error> {
        capturedOptions = options
        return AsyncThrowingStream { continuation in
            continuation.yield(AIStreamChunk(text: "ok", finishReason: "stop"))
            continuation.finish()
        }
    }
}
