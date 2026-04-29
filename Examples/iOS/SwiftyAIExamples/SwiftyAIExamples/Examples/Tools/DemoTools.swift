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

    struct TipInput: Decodable {
        let bill: Double
        let percent: Double
    }

    struct TipOutput: Encodable {
        let tip: Double
        let total: Double
    }

    static let calculateTip = tool(
        name: "calculate_tip",
        description: "Calculates a restaurant tip and total.",
        inputSchema: .object(
            properties: [
                "bill": .number(description: "Bill amount before tip.", minimum: 0),
                "percent": .number(description: "Tip percentage.", minimum: 0)
            ],
            required: ["bill", "percent"]
        ),
        outputSchema: .object(
            properties: [
                "tip": .number(),
                "total": .number()
            ],
            required: ["tip", "total"]
        )
    ) { (input: TipInput) in
        let bill = input.bill
        let percent = input.percent
        let tip = bill * percent / 100
        let total = bill + tip
        return TipOutput(tip: tip, total: total)
    }

    static let lookupDemoOrder = dynamicTool(
        name: "lookup_demo_order",
        description: "Looks up a fake order status for demo IDs A100, B200, or C300.",
        inputSchema: .object(
            properties: [
                "orderID": .string(description: "Demo order identifier.", minLength: 1)
            ],
            required: ["orderID"]
        )
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
}
