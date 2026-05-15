import Foundation

enum JSONExtraction {
    static func extract(from text: String) -> String? {
        let trimmed = trim(text)
        if isValidJSON(trimmed) {
            return trimmed
        }

        for candidate in fencedCodeCandidates(in: text) {
            let trimmedCandidate = trim(candidate)
            if isValidJSON(trimmedCandidate) {
                return trimmedCandidate
            }
        }

        return firstBalancedJSONCandidate(in: text)
    }

    private static func fencedCodeCandidates(in text: String) -> [String] {
        let pattern = #"```(?:json|JSON)?\s*([\s\S]*?)```"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, options: [], range: range).compactMap { match in
            guard match.numberOfRanges > 1,
                  let captureRange = Range(match.range(at: 1), in: text) else {
                return nil
            }
            return String(text[captureRange])
        }
    }

    private static func firstBalancedJSONCandidate(in text: String) -> String? {
        var index = text.startIndex
        while index < text.endIndex {
            let character = text[index]
            if character == "{" || character == "[" {
                if let candidate = balancedCandidate(in: text, from: index),
                   isValidJSON(candidate) {
                    return candidate
                }
            }
            index = text.index(after: index)
        }
        return nil
    }

    private static func balancedCandidate(in text: String, from start: String.Index) -> String? {
        let opening = text[start]
        let closing: Character = opening == "{" ? "}" : "]"
        var stack: [Character] = [closing]
        var isInString = false
        var isEscaped = false
        var index = text.index(after: start)

        while index < text.endIndex {
            let character = text[index]

            if isInString {
                if isEscaped {
                    isEscaped = false
                } else if character == "\\" {
                    isEscaped = true
                } else if character == "\"" {
                    isInString = false
                }
            } else {
                if character == "\"" {
                    isInString = true
                } else if character == "{" {
                    stack.append("}")
                } else if character == "[" {
                    stack.append("]")
                } else if character == "}" || character == "]" {
                    guard stack.last == character else { return nil }
                    stack.removeLast()
                    if stack.isEmpty {
                        let end = text.index(after: index)
                        return String(text[start..<end])
                    }
                }
            }

            index = text.index(after: index)
        }

        return nil
    }

    private static func isValidJSON(_ string: String) -> Bool {
        guard let data = string.data(using: .utf8), !data.isEmpty else {
            return false
        }
        return (try? JSONSerialization.jsonObject(with: data)) != nil
    }

    private static func trim(_ string: String) -> String {
        string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
