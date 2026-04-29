import Foundation

func pruneMessages(_ messages: [ChatMessage], maxMessages: Int) -> [ChatMessage] {
    guard !messages.isEmpty else { return [] }

    let protected = protectedMessageIndices(in: messages)
    var selected = protected

    if selected.isEmpty, let lastIndex = messages.indices.last {
        selected.insert(lastIndex)
    }

    let targetCount = max(maxMessages, selected.count)

    if targetCount > selected.count {
        for index in messages.indices.reversed() {
            if selected.count >= targetCount { break }
            selected.insert(index)
        }
    }

    return messages.indices.compactMap { index in
        selected.contains(index) ? messages[index] : nil
    }
}

func protectedMessageIndices(in messages: [ChatMessage]) -> Set<Int> {
    var indices = Set<Int>()

    if let systemIndex = messages.firstIndex(where: { $0.role == .system }) {
        indices.insert(systemIndex)
    }

    if let latestUserIndex = messages.lastIndex(where: { $0.role == .user }) {
        indices.insert(latestUserIndex)
    }

    return indices
}
