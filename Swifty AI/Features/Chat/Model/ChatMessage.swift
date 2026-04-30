import Foundation

public struct ChatMessage: Sendable, Identifiable {
    public let id: String
    public let role: ChatRole
    public var content: String {
        didSet {
            guard !isSynchronizingContent else { return }
            isSynchronizingContent = true
            parts = [.text(content)]
            isSynchronizingContent = false
        }
    }
    public var parts: [AIMessageContent] {
        didSet {
            guard !isSynchronizingContent else { return }
            isSynchronizingContent = true
            content = parts.textContent
            isSynchronizingContent = false
        }
    }
    public let createdAt: Date
    private var isSynchronizingContent = false

    public init(id: String = generateId(), role: ChatRole, content: String, createdAt: Date = .now) {
        self.id = id
        self.role = role
        self.content = content
        self.parts = [.text(content)]
        self.createdAt = createdAt
    }

    public init(id: String = generateId(), role: ChatRole, parts: [AIMessageContent], createdAt: Date = .now) {
        self.id = id
        self.role = role
        self.content = parts.textContent
        self.parts = parts
        self.createdAt = createdAt
    }
}

public enum ChatRole: String, Sendable {
    case user
    case assistant
    case system
}
