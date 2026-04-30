import Foundation

public struct AISchema: Sendable {
    public var type: AISchemaType?
    public var description: String?
    public var properties: [String: AISchema]
    public var required: [String]
    private var itemSchemas: [AISchema]
    public var enumValues: [String]?
    public var nullable: Bool
    public var minimum: Double?
    public var maximum: Double?
    public var minLength: Int?
    public var maxLength: Int?
    public var pattern: String?

    public init(
        type: AISchemaType? = nil,
        description: String? = nil,
        properties: [String: AISchema] = [:],
        required: [String] = [],
        items: AISchema? = nil,
        enumValues: [String]? = nil,
        nullable: Bool = false,
        minimum: Double? = nil,
        maximum: Double? = nil,
        minLength: Int? = nil,
        maxLength: Int? = nil,
        pattern: String? = nil
    ) {
        self.type = type
        self.description = description
        self.properties = properties
        self.required = required
        self.itemSchemas = items.map { [$0] } ?? []
        self.enumValues = enumValues
        self.nullable = nullable
        self.minimum = minimum
        self.maximum = maximum
        self.minLength = minLength
        self.maxLength = maxLength
        self.pattern = pattern
    }

    public static func object(
        properties: [String: AISchema],
        required: [String]? = nil,
        description: String? = nil
    ) -> AISchema {
        AISchema(
            type: .object,
            description: description,
            properties: properties,
            required: required ?? Array(properties.keys).sorted()
        )
    }

    public static func array(of item: AISchema, description: String? = nil) -> AISchema {
        AISchema(type: .array, description: description, items: item)
    }

    public static func string(
        description: String? = nil,
        minLength: Int? = nil,
        maxLength: Int? = nil,
        pattern: String? = nil
    ) -> AISchema {
        AISchema(type: .string, description: description, minLength: minLength, maxLength: maxLength, pattern: pattern)
    }

    public static func integer(description: String? = nil, minimum: Double? = nil, maximum: Double? = nil) -> AISchema {
        AISchema(type: .integer, description: description, minimum: minimum, maximum: maximum)
    }

    public static func number(description: String? = nil, minimum: Double? = nil, maximum: Double? = nil) -> AISchema {
        AISchema(type: .number, description: description, minimum: minimum, maximum: maximum)
    }

    public static func boolean(description: String? = nil) -> AISchema {
        AISchema(type: .boolean, description: description)
    }

    public static func enumeration(_ values: [String], description: String? = nil) -> AISchema {
        AISchema(type: .string, description: description, enumValues: values)
    }

    public func optional() -> AISchema {
        var copy = self
        copy.nullable = true
        return copy
    }

    public var jsonSchema: [String: Any] {
        var result: [String: Any] = [:]
        if let type {
            result["type"] = nullable ? [type.rawValue, "null"] : type.rawValue
        }
        if let description { result["description"] = description }
        if !properties.isEmpty {
            result["properties"] = properties.mapValues(\.jsonSchema)
        }
        if !required.isEmpty { result["required"] = required }
        if let items { result["items"] = items.jsonSchema }
        if let enumValues { result["enum"] = enumValues }
        if let minimum { result["minimum"] = minimum }
        if let maximum { result["maximum"] = maximum }
        if let minLength { result["minLength"] = minLength }
        if let maxLength { result["maxLength"] = maxLength }
        if let pattern { result["pattern"] = pattern }
        return result
    }

    public var items: AISchema? {
        get { itemSchemas.first }
        set { itemSchemas = newValue.map { [$0] } ?? [] }
    }
}

public enum AISchemaType: String, Sendable {
    case object
    case array
    case string
    case number
    case integer
    case boolean
}

public protocol AISchemaConvertible {
    static var aiSchema: AISchema { get }
}

extension JSONSchemaConvertible {
    public static var aiSchemaFromJSONSchema: AISchema {
        AISchema(jsonSchema: jsonSchema)
    }
}

public struct AISchemaValidationIssue: Sendable, Equatable {
    public let path: String
    public let message: String

    public init(path: String, message: String) {
        self.path = path
        self.message = message
    }
}

extension AISchema {
    public init(jsonSchema: [String: Any]) {
        let typeValue: String?
        if let type = jsonSchema["type"] as? String {
            typeValue = type
        } else if let types = jsonSchema["type"] as? [String] {
            typeValue = types.first { $0 != "null" }
        } else {
            typeValue = nil
        }

        let properties = (jsonSchema["properties"] as? [String: Any])?.compactMapValues { value -> AISchema? in
            guard let object = value as? [String: Any] else { return nil }
            return AISchema(jsonSchema: object)
        } ?? [:]

        let itemSchema: AISchema?
        if let itemObject = jsonSchema["items"] as? [String: Any] {
            itemSchema = AISchema(jsonSchema: itemObject)
        } else {
            itemSchema = nil
        }

        self.init(
            type: typeValue.flatMap(AISchemaType.init(rawValue:)),
            description: jsonSchema["description"] as? String,
            properties: properties,
            required: jsonSchema["required"] as? [String] ?? [],
            items: itemSchema,
            enumValues: jsonSchema["enum"] as? [String],
            nullable: (jsonSchema["type"] as? [String])?.contains("null") ?? false,
            minimum: jsonSchema["minimum"] as? Double,
            maximum: jsonSchema["maximum"] as? Double,
            minLength: jsonSchema["minLength"] as? Int,
            maxLength: jsonSchema["maxLength"] as? Int,
            pattern: jsonSchema["pattern"] as? String
        )
    }

    public func validate(_ value: Any, path: String = "$") -> [AISchemaValidationIssue] {
        if value is NSNull {
            return nullable ? [] : [.init(path: path, message: "Value is null")]
        }

        var issues: [AISchemaValidationIssue] = []

        switch type {
        case .object:
            guard let object = value as? [String: Any] else {
                return [.init(path: path, message: "Expected object")]
            }
            for key in required where object[key] == nil {
                issues.append(.init(path: "\(path).\(key)", message: "Missing required field"))
            }
            for (key, schema) in properties {
                guard let child = object[key] else { continue }
                issues.append(contentsOf: schema.validate(child, path: "\(path).\(key)"))
            }
        case .array:
            guard let array = value as? [Any] else {
                return [.init(path: path, message: "Expected array")]
            }
            if let items {
                for (index, child) in array.enumerated() {
                    issues.append(contentsOf: items.validate(child, path: "\(path)[\(index)]"))
                }
            }
        case .string:
            guard let string = value as? String else {
                return [.init(path: path, message: "Expected string")]
            }
            if let enumValues, !enumValues.contains(string) {
                issues.append(.init(path: path, message: "Expected one of \(enumValues.joined(separator: ", "))"))
            }
            if let minLength, string.count < minLength {
                issues.append(.init(path: path, message: "Expected at least \(minLength) characters"))
            }
            if let maxLength, string.count > maxLength {
                issues.append(.init(path: path, message: "Expected at most \(maxLength) characters"))
            }
            if let pattern, string.range(of: pattern, options: .regularExpression) == nil {
                issues.append(.init(path: path, message: "Expected to match pattern \(pattern)"))
            }
        case .number:
            guard let number = numericValue(value) else {
                return [.init(path: path, message: "Expected number")]
            }
            issues.append(contentsOf: validateRange(number, path: path))
        case .integer:
            if let int = value as? Int {
                issues.append(contentsOf: validateRange(Double(int), path: path))
            } else if let number = value as? NSNumber, floor(number.doubleValue) == number.doubleValue {
                issues.append(contentsOf: validateRange(number.doubleValue, path: path))
            } else {
                return [.init(path: path, message: "Expected integer")]
            }
        case .boolean:
            if !(value is Bool) {
                return [.init(path: path, message: "Expected boolean")]
            }
        case nil:
            break
        }

        return issues
    }

    private func validateRange(_ value: Double, path: String) -> [AISchemaValidationIssue] {
        var issues: [AISchemaValidationIssue] = []
        if let minimum, value < minimum {
            issues.append(.init(path: path, message: "Expected value >= \(minimum)"))
        }
        if let maximum, value > maximum {
            issues.append(.init(path: path, message: "Expected value <= \(maximum)"))
        }
        return issues
    }

    private func numericValue(_ value: Any) -> Double? {
        if let double = value as? Double { return double }
        if let int = value as? Int { return Double(int) }
        if let number = value as? NSNumber { return number.doubleValue }
        return nil
    }
}

@propertyWrapper
public struct Guide<Value> {
    public var wrappedValue: Value
    public let description: String?
    public let minimum: Double?
    public let maximum: Double?
    public let minLength: Int?
    public let maxLength: Int?
    public let pattern: String?

    public init(
        wrappedValue: Value,
        _ description: String? = nil,
        minimum: Double? = nil,
        maximum: Double? = nil,
        minLength: Int? = nil,
        maxLength: Int? = nil,
        pattern: String? = nil
    ) {
        self.wrappedValue = wrappedValue
        self.description = description
        self.minimum = minimum
        self.maximum = maximum
        self.minLength = minLength
        self.maxLength = maxLength
        self.pattern = pattern
    }
}

extension Guide: Codable where Value: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(wrappedValue: try container.decode(Value.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

extension Guide: Sendable where Value: Sendable {}
