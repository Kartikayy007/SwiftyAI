import Foundation

enum MessageHistoryTruncationStrategy: Equatable {
    case lastMessages(Int)
    case approximateTokens(Int)
    case preserveSystemAndLastUser
}

func truncateMessages(
    _ messages: [ChatMessage],
    strategy: MessageHistoryTruncationStrategy,
    contextWindow: ContextWindow = ContextWindow(maxTokens: 128_000)
) -> [ChatMessage] {
    switch strategy {
    case .lastMessages(let count):
        return pruneMessages(messages, maxMessages: count)
    case .approximateTokens(let limit):
        return truncateMessagesByApproximateTokens(messages, maxTokens: limit, contextWindow: contextWindow)
    case .preserveSystemAndLastUser:
        return pruneMessages(messages, maxMessages: 0)
    }
}

private func truncateMessagesByApproximateTokens(
    _ messages: [ChatMessage],
    maxTokens: Int,
    contextWindow: ContextWindow
) -> [ChatMessage] {
    guard !messages.isEmpty else { return [] }

    var selected = Set(messages.indices)
    let protected = protectedMessageIndices(in: messages)
    let protectedOrFallback: Set<Int>

    if protected.isEmpty, let lastIndex = messages.indices.last {
        protectedOrFallback = [lastIndex]
    } else {
        protectedOrFallback = protected
    }

    while contextWindow.estimatedTokens(for: selectedMessages(messages, selected: selected)) > maxTokens {
        guard let removableIndex = messages.indices.first(where: { selected.contains($0) && !protectedOrFallback.contains($0) }) else {
            break
        }

        selected.remove(removableIndex)
    }

    return selectedMessages(messages, selected: selected)
}

private func selectedMessages(_ messages: [ChatMessage], selected: Set<Int>) -> [ChatMessage] {
    messages.indices.compactMap { index in
        selected.contains(index) ? messages[index] : nil
    }
}
