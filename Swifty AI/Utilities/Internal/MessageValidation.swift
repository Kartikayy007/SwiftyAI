import Foundation

enum UIMessageValidationError: Error, Equatable {
    case emptyConversation
    case duplicateId(String)
    case emptyContent(messageId: String)
    case orphanToolResult(messageId: String, toolCallId: String)
    case invalidToolResultOrder(messageId: String, toolCallId: String)
}

func validateUIMessages(_ messages: [ChatMessage]) throws {
    guard !messages.isEmpty else {
        throw UIMessageValidationError.emptyConversation
    }

    var ids = Set<String>()

    for message in messages {
        guard ids.insert(message.id).inserted else {
            throw UIMessageValidationError.duplicateId(message.id)
        }

        guard message.parts.contains(where: \.hasMeaningfulContent) else {
            throw UIMessageValidationError.emptyContent(messageId: message.id)
        }
    }
}

private extension AIMessageContent {
    var hasMeaningfulContent: Bool {
        switch self {
        case .text(let text):
            return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .imageURL:
            return true
        case .imageBase64(let base64, _, _):
            return !base64.isEmpty
        case .imageData(let data, _, _):
            return !data.isEmpty
        case .pdfURL:
            return true
        case .pdfBase64(let base64, _):
            return !base64.isEmpty
        case .pdfData(let data, _):
            return !data.isEmpty
        case .audioBase64(let base64, _, _):
            return !base64.isEmpty
        case .audioData(let data, _, _):
            return !data.isEmpty
        case .videoURL:
            return true
        case .videoBase64(let base64, _, _):
            return !base64.isEmpty
        case .videoData(let data, _, _):
            return !data.isEmpty
        case .fileURL:
            return true
        case .fileBase64(let base64, _, _):
            return !base64.isEmpty
        case .fileData(let data, _, _):
            return !data.isEmpty
        }
    }
}
