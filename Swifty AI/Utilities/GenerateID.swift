import Foundation

public func generateId() -> String {
    UUID().uuidString
}

public func generateId(prefix: String) -> String {
    "\(prefix)_\(generateId())"
}
