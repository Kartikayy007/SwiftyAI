import Foundation

public protocol JSONSchemaConvertible {
    static var schemaName: String { get }
    static var jsonSchema: [String: Any] { get }
}
