import Foundation
import SwiftyAI

struct RecipeSummary: Decodable, JSONSchemaConvertible {
    let title: String
    let servings: Int
    let prepMinutes: Int
    let ingredients: [String]
    let steps: [String]

    static let schemaName = "RecipeSummary"

    static var jsonSchema: [String: Any] {
        [
            "type": "object",
            "required": ["title", "servings", "prepMinutes", "ingredients", "steps"],
            "properties": [
                "title": ["type": "string"],
                "servings": ["type": "integer"],
                "prepMinutes": ["type": "integer"],
                "ingredients": ["type": "array", "items": ["type": "string"]],
                "steps": ["type": "array", "items": ["type": "string"]]
            ]
        ]
    }
}
