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

    private struct GuidedTicket: Codable, Equatable {
        @Guide("Short customer-visible title", minLength: 3, maxLength: 80)
        var title: String = ""
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

    func testSchemaValidationRejectsWrongPrimitiveType() async throws {
        let mock = MockAIModel.success(#"{"name":"Ritik","age":"old"}"#)

        do {
            _ = try await generateObject(model: mock, prompt: "person", output: .object(Person.self))
            XCTFail("Expected schema validation error")
        } catch AIError.schemaValidationFailed(let issues) {
            XCTAssertTrue(issues.contains { $0.path == "$.age" && $0.message.contains("integer") })
        }
    }

    func testSchemaValidationRejectsMissingRequiredField() async throws {
        let mock = MockAIModel.success(#"{"name":"Ritik"}"#)

        do {
            _ = try await generateObject(model: mock, prompt: "person", output: .object(Person.self))
            XCTFail("Expected schema validation error")
        } catch AIError.schemaValidationFailed(let issues) {
            XCTAssertTrue(issues.contains { $0.path == "$.age" && $0.message.contains("Missing required") })
        }
    }

    func testArraySchemaValidationRejectsInvalidItem() async throws {
        let mock = MockAIModel.success(#"[{"name":"A","age":1},{"name":"B","age":-1}]"#)

        do {
            _ = try await generateObject(model: mock, prompt: "people", output: Output<[Person]>.array(Person.self))
            XCTFail("Expected schema validation error")
        } catch AIError.schemaValidationFailed(let issues) {
            XCTAssertTrue(issues.contains { $0.path == "$[1].age" })
        }
    }

    func testEnumOutputRejectsUnknownValue() async throws {
        let mock = MockAIModel.success(#""urgent""#)

        do {
            _ = try await generateObject(model: mock, prompt: "priority", output: Output<Priority>.enumeration(Priority.self))
            XCTFail("Expected enum validation failure")
        } catch AIError.schemaValidationFailed(let issues) {
            XCTAssertTrue(issues.contains { $0.path == "$" })
        }
    }

    func testGuideEncodesAndDecodesOnlyWrappedValue() throws {
        let ticket = GuidedTicket(title: "Payment failed")
        let data = try JSONEncoder().encode(ticket)
        let json = String(data: data, encoding: .utf8)

        XCTAssertEqual(json, #"{"title":"Payment failed"}"#)

        let decoded = try JSONDecoder().decode(GuidedTicket.self, from: Data(#"{"title":"Refund pending"}"#.utf8))
        XCTAssertEqual(decoded.title, "Refund pending")
    }

    func testGuideInitializerStoresMetadata() {
        let guide = Guide(wrappedValue: "abc", "A title", minimum: 1, maximum: 10, minLength: 2, maxLength: 20, pattern: "^[a-z]+$")

        XCTAssertEqual(guide.wrappedValue, "abc")
        XCTAssertEqual(guide.description, "A title")
        XCTAssertEqual(guide.minimum, 1)
        XCTAssertEqual(guide.maximum, 10)
        XCTAssertEqual(guide.minLength, 2)
        XCTAssertEqual(guide.maxLength, 20)
        XCTAssertEqual(guide.pattern, "^[a-z]+$")
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
