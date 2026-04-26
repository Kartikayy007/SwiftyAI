import Testing
@testable import Swifty_AI

struct Swifty_AITests {
    @Test func mockModelReturnsText() async throws {
        let model = MockAIModel.success("hi")
        let response = try await model.generate("hello")
        #expect(response.text == "hi")
    }
}
