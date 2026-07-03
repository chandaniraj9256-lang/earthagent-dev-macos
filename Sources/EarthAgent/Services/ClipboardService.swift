import AppKit
import Foundation

enum ClipboardServiceError: LocalizedError {
    case noText

    var errorDescription: String? {
        switch self {
        case .noText:
            return "The clipboard does not contain readable text."
        }
    }
}

final class ClipboardService {
    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    func readText(limit: Int = 18_000) throws -> String {
        guard let text = pasteboard.string(forType: .string)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !text.isEmpty else {
            throw ClipboardServiceError.noText
        }

        if text.count <= limit {
            return text
        }

        return String(text.prefix(limit)) + "\n\n[Clipboard text was truncated for safety.]"
    }

    func writeText(_ text: String) throws {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            throw ClipboardServiceError.noText
        }
        pasteboard.clearContents()
        pasteboard.setString(clean, forType: .string)
    }
}
