import Foundation

public struct Output<T: Decodable> {
    public let schema: AISchema
    public let decode: (Data) throws -> T

    public init(schema: AISchema, decode: @escaping (Data) throws -> T = { try JSONDecoder().decode(T.self, from: $0) }) {
        self.schema = schema
        self.decode = decode
    }

    public static func object(_ type: T.Type = T.self) -> Output<T> where T: AISchemaConvertible {
        Output<T>(schema: T.aiSchema)
    }

    public static func array<Element>(_ type: Element.Type) -> Output<[Element]> where T == [Element], Element: Decodable & AISchemaConvertible {
        Output<[Element]>(schema: .array(of: Element.aiSchema))
    }

    public static func array<Element>(_ type: Element.Type, itemSchema: AISchema) -> Output<[Element]> where T == [Element], Element: Decodable {
        Output<[Element]>(schema: .array(of: itemSchema))
    }

    public static func enumeration<E>(_ type: E.Type) -> Output<E> where T == E, E: RawRepresentable & CaseIterable & Decodable, E.RawValue == String {
        Output<E>(
            schema: .enumeration(E.allCases.map(\.rawValue)),
            decode: { data in
                let raw = try JSONDecoder().decode(String.self, from: data)
                guard let value = E(rawValue: raw) else {
                    throw AIError.schemaValidationFailed([.init(path: "$", message: "Unknown enum value \(raw)")])
                }
                return value
            }
        )
    }
}

public struct ObjectStreamChunk<T: Decodable> {
    public let textDelta: String
    public let partialJSON: String
    public let partialObject: T?
    public let object: T?
    public let usage: TokenUsage?
    public let finishReason: String?
    public let validationIssues: [AISchemaValidationIssue]

    public init(
        textDelta: String = "",
        partialJSON: String = "",
        partialObject: T? = nil,
        object: T? = nil,
        usage: TokenUsage? = nil,
        finishReason: String? = nil,
        validationIssues: [AISchemaValidationIssue] = []
    ) {
        self.textDelta = textDelta
        self.partialJSON = partialJSON
        self.partialObject = partialObject
        self.object = object
        self.usage = usage
        self.finishReason = finishReason
        self.validationIssues = validationIssues
    }
}
