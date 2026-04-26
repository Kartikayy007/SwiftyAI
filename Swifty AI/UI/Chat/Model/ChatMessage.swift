import Foundation

public struct ChatMessage: Sendable, Identifiable {
    public let id: String
    public let role: ChatRole
    public var content: String
    public let createdAt: Date

    public init(id: String = UUID().uuidString, role: ChatRole, content: String, createdAt: Date = .now) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
    }
}

public enum ChatRole: String, Sendable {
    case user
    case assistant
    case system
}
