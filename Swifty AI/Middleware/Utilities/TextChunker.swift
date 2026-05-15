enum TextChunker {
    static func chunks(_ text: String, maxLength: Int) -> [String] {
        guard !text.isEmpty else { return [] }
        let maxLength = max(1, maxLength)
        var chunks: [String] = []
        var start = text.startIndex

        while start < text.endIndex {
            let end = text.index(start, offsetBy: maxLength, limitedBy: text.endIndex) ?? text.endIndex
            chunks.append(String(text[start..<end]))
            start = end
        }

        return chunks
    }
}
