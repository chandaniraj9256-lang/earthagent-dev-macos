import Foundation

enum SpokenTextCleaner {
    static func clean(_ text: String, limit: Int = 420) -> String {
        var clean = removeCodeBlocks(from: text)
        clean = clean
            .components(separatedBy: .newlines)
            .map(cleanLine)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        clean = removeURLs(from: clean)
        clean = clean
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "__", with: "")
            .replacingOccurrences(of: "`", with: "")
            .replacingOccurrences(of: "|", with: ", ")
            .replacingOccurrences(of: "  ", with: " ")

        clean = removeEmojiLikeScalars(from: clean)
        clean = collapseWhitespace(clean)

        guard !clean.isEmpty else { return "I have the answer in the chat." }
        guard clean.count > limit else { return clean }

        let prefix = String(clean.prefix(limit))
        let sentenceEndings: Set<Character> = [".", "?", "!"]
        if let end = prefix.lastIndex(where: { sentenceEndings.contains($0) }) {
            return String(prefix[...end])
        }
        return "\(prefix.trimmingCharacters(in: .whitespacesAndNewlines)). More detail is in the chat."
    }

    private static func removeCodeBlocks(from text: String) -> String {
        var output = ""
        var isInCodeBlock = false

        for line in text.components(separatedBy: .newlines) {
            if line.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("```") {
                isInCodeBlock.toggle()
                continue
            }
            if !isInCodeBlock {
                output += line + "\n"
            }
        }

        return output
    }

    private static func cleanLine(_ line: String) -> String {
        var trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        while trimmed.hasPrefix("#") {
            trimmed.removeFirst()
            trimmed = trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let bulletPrefixes = ["- ", "* ", "+ ", "• "]
        for prefix in bulletPrefixes where trimmed.hasPrefix(prefix) {
            trimmed.removeFirst(prefix.count)
            return trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let dotIndex = trimmed.firstIndex(of: ".") {
            let number = trimmed[..<dotIndex]
            if !number.isEmpty, number.allSatisfy(\.isNumber) {
                trimmed = String(trimmed[trimmed.index(after: dotIndex)...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        return trimmed
    }

    private static func removeURLs(from text: String) -> String {
        text.replacingOccurrences(
            of: #"https?://\S+|www\.\S+"#,
            with: "",
            options: .regularExpression
        )
    }

    private static func removeEmojiLikeScalars(from text: String) -> String {
        String(text.unicodeScalars.filter { scalar in
            if scalar.properties.isEmojiPresentation { return false }
            if scalar.value >= 0x1F300 && scalar.value <= 0x1FAFF { return false }
            return true
        })
    }

    private static func collapseWhitespace(_ text: String) -> String {
        text.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
        )
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
