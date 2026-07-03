import AppKit
import Foundation

final class BrowserUseService {
    private let automation: AutomationService
    private let computerControl: ComputerControlService

    init(automation: AutomationService, computerControl: ComputerControlService) {
        self.automation = automation
        self.computerControl = computerControl
    }

    func openSearch(query: String) {
        automation.openWebsite(searchURL(for: query))
    }

    func focusAddressBarAndSearch(query: String) throws {
        try computerControl.pressShortcut("cmd+l")
        Thread.sleep(forTimeInterval: 0.15)
        try computerControl.typeTextIntoFocusedField(searchURL(for: query).absoluteString)
        Thread.sleep(forTimeInterval: 0.10)
        try computerControl.pressShortcut("return")
    }

    func inspectBrowserElements(limit: Int = 20) throws -> [AccessibilityElementSnapshot] {
        try computerControl.inspectVisibleElements(limit: limit)
    }

    func readResultCandidates(from elements: [AccessibilityElementSnapshot]) -> [BrowserResultCandidate] {
        var candidates: [BrowserResultCandidate] = []

        for element in elements {
            let text = element.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard text.count >= 3 else { continue }
            let lower = text.lowercased()
            let role = element.role.lowercased()
            let isLikelyResult = element.canPress ||
                role.contains("link") ||
                lower.contains("http") ||
                lower.contains("www.") ||
                lower.contains(".com") ||
                lower.contains("search") ||
                lower.contains("result")

            guard isLikelyResult else { continue }
            let kind = classify(text: text)
            let candidate = BrowserResultCandidate(
                id: candidates.count + 1,
                elementID: element.id,
                title: cleanedTitle(text),
                kind: kind,
                canOpen: element.canPress
            )
            if !candidates.contains(where: { $0.title.caseInsensitiveCompare(candidate.title) == .orderedSame }) {
                candidates.append(candidate)
            }
            if candidates.count >= 10 { break }
        }

        return candidates
    }

    func searchURL(for query: String) -> URL {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return URL(string: "https://www.google.com/search?q=\(encoded)")!
    }

    private func classify(text: String) -> BrowserResultCandidate.Kind {
        let lower = text.lowercased()
        if lower.contains(".pdf") || lower.contains("document") || lower.contains("file") {
            return .document
        }
        if lower.contains("youtube") || lower.contains("video") || lower.contains("watch") {
            return .media
        }
        if lower.contains("search") || lower.contains("next") || lower.contains("result") {
            return .pageControl
        }
        if lower.contains("http") || lower.contains("www.") || lower.contains(".com") || lower.contains(".org") || lower.contains(".net") {
            return .website
        }
        return .searchResult
    }

    private func cleanedTitle(_ text: String) -> String {
        let collapsed = text
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if collapsed.count <= 90 { return collapsed }
        return String(collapsed.prefix(87)) + "..."
    }
}
