import XCTest
@testable import Swifty_AI

final class StructuredOutputAdvancedTests: XCTestCase {
    private struct Person: Codable, Sendable, AISchemaConvertible {
        let name: String
        let age: Int

        static var aiSchema: AISchema {
            .object(
                properties: [
                    "name": .string(description: "Display name", minLength: 1),
                    "age": .integer(minimum: 0)
                ],
                required: ["name", "age"]
            )
        }
    }

    private enum Priority: String, Codable, CaseIterable {
        case low
        case medium
        case high
    }

    func testOutputObjectDecodesAndValidates() async throws {
        let mock = MockAIModel.success(#"{"name":"Ritik","age":25}"#)
        let result = try await generateObject(model: mock, prompt: "person", output: .object(Person.self))

        XCTAssertEqual(result.object.name, "Ritik")
        XCTAssertEqual(result.object.age, 25)
    }

    func testOutputArrayDecodes() async throws {
        let mock = MockAIModel.success(#"[{"name":"A","age":1},{"name":"B","age":2}]"#)
        let result = try await generateObject(model: mock, prompt: "people", output: Output<[Person]>.array(Person.self))

        XCTAssertEqual(result.object.count, 2)
        XCTAssertEqual(result.object[1].name, "B")
    }

    func testOutputEnumDecodes() async throws {
        let mock = MockAIModel.success(#""high""#)
        let result = try await generateObject(model: mock, prompt: "priority", output: Output<Priority>.enumeration(Priority.self))

        XCTAssertEqual(result.object, .high)
    }

    func testSchemaValidationErrorsAreFirstClass() async throws {
        let mock = MockAIModel.success(#"{"name":"","age":-1}"#)

        do {
            _ = try await generateObject(model: mock, prompt: "person", output: .object(Person.self))
            XCTFail("Expected schema validation error")
        } catch AIError.schemaValidationFailed(let issues) {
            XCTAssertTrue(issues.contains { $0.path == "$.name" })
            XCTAssertTrue(issues.contains { $0.path == "$.age" })
        }
    }

    func testStreamObjectYieldsPartialAndFinalObject() async throws {
        let model = MockStreamModel()
        model.chunks = [
            AIStreamChunk(text: #"{"name":"Ri"#, finishReason: nil, usage: nil),
            AIStreamChunk(text: #"tik","age":25}"#, finishReason: "stop", usage: TokenUsage(inputTokens: 5, outputTokens: 8))
        ]

        var chunks: [ObjectStreamChunk<Person>] = []
        for try await chunk in streamObject(model: model, prompt: "person", output: .object(Person.self)) {
            chunks.append(chunk)
        }

        XCTAssertTrue(chunks.contains { !$0.textDelta.isEmpty })
        XCTAssertEqual(chunks.last?.object?.name, "Ritik")
        XCTAssertEqual(chunks.last?.usage?.outputTokens, 8)
        XCTAssertEqual(chunks.last?.finishReason, "stop")
    }
}
