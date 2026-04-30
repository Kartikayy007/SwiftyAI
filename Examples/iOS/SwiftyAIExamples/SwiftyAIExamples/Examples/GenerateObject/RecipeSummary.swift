import Foundation
import SwiftyAI

struct RecipeSummary: Decodable, AISchemaConvertible {
    let title: String
    let servings: Int
    let prepMinutes: Int
    let ingredients: [String]
    let steps: [String]

    static var aiSchema: AISchema {
        .object(
            properties: [
                "title": .string(description: "Short recipe title", minLength: 1),
                "servings": .integer(description: "Number of servings", minimum: 1),
                "prepMinutes": .integer(description: "Preparation time in minutes", minimum: 1),
                "ingredients": .array(of: .string(minLength: 1)),
                "steps": .array(of: .string(minLength: 1))
            ],
            required: ["title", "servings", "prepMinutes", "ingredients", "steps"]
        )
    }
}

struct IngredientIdea: Decodable, AISchemaConvertible, Identifiable {
    let name: String
    let role: String

    var id: String { "\(name)-\(role)" }

    static var aiSchema: AISchema {
        .object(
            properties: [
                "name": .string(description: "Ingredient name", minLength: 1),
                "role": .string(description: "How it is used", minLength: 1)
            ],
            required: ["name", "role"]
        )
    }
}

enum MealCategory: String, Decodable, CaseIterable {
    case breakfast
    case lunch
    case dinner
    case snack
}
