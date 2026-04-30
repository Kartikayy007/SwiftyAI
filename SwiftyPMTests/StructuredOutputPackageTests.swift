import XCTest
import SwiftyAI

final class StructuredOutputPackageTests: XCTestCase {
    struct Item: Codable, AISchemaConvertible {
        let name: String

        static var aiSchema: AISchema {
            .object(properties: ["name": .string(minLength: 1)], required: ["name"])
        }
    }

    func testOutputObjectExposesSchema() {
        let output = Output<Item>.object(Item.self)
        XCTAssertEqual(output.schema.jsonSchema["type"] as? String, "object")
    }

    func testToolHelperExposesInputAndOutputSchemas() {
        struct Input: Decodable { let value: String }
        struct Result: Encodable { let value: String }

        let echo = tool(
            name: "echo",
            description: "Echoes a value",
            inputSchema: .object(properties: ["value": .string()]),
            outputSchema: .object(properties: ["value": .string()])
        ) { (input: Input) in
            Result(value: input.value)
        }

        XCTAssertEqual(echo.parameters["type"] as? String, "object")
        XCTAssertNotNil(echo.outputSchema)
    }
}
