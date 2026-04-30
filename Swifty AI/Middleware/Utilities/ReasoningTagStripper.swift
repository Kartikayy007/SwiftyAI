import Foundation

enum ReasoningTagStripper {
    static func strip(_ text: String, tags: [String]) -> String {
        var result = text
        for tag in tags where !tag.isEmpty {
            result = strip(tag: tag, from: result)
        }
        return normalize(result)
    }

    private static func strip(tag: String, from text: String) -> String {
        let escapedTag = NSRegularExpression.escapedPattern(for: tag)
        let pattern = #"<\s*\#(escapedTag)\b[^>]*>[\s\S]*?<\s*/\s*\#(escapedTag)\s*>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return text
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
    }

    private static func normalize(_ text: String) -> String {
        let collapsed = text.replacingOccurrences(
            of: #"\n{3,}"#,
            with: "\n\n",
            options: .regularExpression
        )
        return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
