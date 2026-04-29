import Foundation
import SwiftyAI

enum DemoTools {
    static let all: [AITool] = [
        currentDate,
        calculateTip,
        lookupDemoOrder
    ]

    static let currentDate = AITool(
        name: "get_current_date",
        description: "Returns the current local date as an ISO-8601 string.",
        parameters: [
            "type": "object",
            "properties": [:],
            "required": []
        ]
    ) { _ in
        ISO8601DateFormatter().string(from: Date())
    }

    static let calculateTip = AITool(
        name: "calculate_tip",
        description: "Calculates a restaurant tip and total.",
        parameters: [
            "type": "object",
            "required": ["bill", "percent"],
            "properties": [
                "bill": ["type": "number", "description": "Bill amount before tip."],
                "percent": ["type": "number", "description": "Tip percentage."]
            ]
        ]
    ) { arguments in
        let bill = try number("bill", in: arguments)
        let percent = try number("percent", in: arguments)
        let tip = bill * percent / 100
        let total = bill + tip
        return String(format: "tip %.2f, total %.2f", tip, total)
    }

    static let lookupDemoOrder = AITool(
        name: "lookup_demo_order",
        description: "Looks up a fake order status for demo IDs A100, B200, or C300.",
        parameters: [
            "type": "object",
            "required": ["orderID"],
            "properties": [
                "orderID": ["type": "string", "description": "Demo order identifier."]
            ]
        ]
    ) { arguments in
        let orderID = arguments["orderID"] as? String ?? arguments["order_id"] as? String ?? ""
        switch orderID.uppercased() {
        case "A100":
            return "A100 is packed and waiting for carrier pickup."
        case "B200":
            return "B200 is out for delivery today."
        case "C300":
            return "C300 needs address confirmation before shipping."
        default:
            throw ExampleError.message("Unknown demo order \(orderID). Use A100, B200, or C300.")
        }
    }

    private static func number(_ key: String, in arguments: [String: Any]) throws -> Double {
        if let value = arguments[key] as? Double { return value }
        if let value = arguments[key] as? Int { return Double(value) }
        if let value = arguments[key] as? String, let parsed = Double(value) { return parsed }
        throw ExampleError.message("Missing numeric argument \(key).")
    }
}
