import XCTest
@testable import Swifty_AI

final class GenerateTextTests: XCTestCase {
    func testGenerateReturnsText() async throws {
        let model = MockAIModel.success("Hello!")
        let response = try await generateText(model: model, prompt: "Hi")
        XCTAssertEqual(response.text, "Hello!")
    }

    func testGenerateForwardsPrompt() async throws {
        var capturedPrompt: String?
        struct CapturingModel: AIModel {
            var capture: (String) -> Void
            func generate(_ prompt: String) async throws -> AIResponse {
                capture(prompt)
                return AIResponse(text: "ok", model: nil, usage: nil, finishReason: nil)
            }
        }
        let model = CapturingModel { capturedPrompt = $0 }
        _ = try await generateText(model: model, prompt: "test prompt")
        XCTAssertEqual(capturedPrompt, "test prompt")
    }

    func testGeneratePropagatesError() async {
        let model = MockAIModel.failure(AIError.invalidResponse)
        do {
            _ = try await generateText(model: model, prompt: "Hi")
            XCTFail("Expected error")
        } catch AIError.invalidResponse {
            // pass
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }
}
