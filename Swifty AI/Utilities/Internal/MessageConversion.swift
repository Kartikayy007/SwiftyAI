import Foundation

struct ModelMessage: Sendable {
    let id: String
    let role: ChatRole
    let content: String
    let parts: [AIMessageContent]
    let createdAt: Date
}

func convertToModelMessages(_ messages: [ChatMessage]) throws -> [ModelMessage] {
    try validateUIMessages(messages)

    return messages.map { message in
        ModelMessage(
            id: message.id,
            role: message.role,
            content: message.content,
            parts: message.parts,
            createdAt: message.createdAt
        )
    }
}
