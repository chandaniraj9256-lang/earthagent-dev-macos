import AppKit
import Foundation

struct WebsiteBuildResult {
    let directory: URL
    let indexFile: URL
}

enum WebsiteBuilderError: LocalizedError {
    case cannotCreateDirectory

    var errorDescription: String? {
        switch self {
        case .cannotCreateDirectory:
            return "Could not create the website folder."
        }
    }
}

final class WebsiteBuilderService {
    func createWebsite(from prompt: String) throws -> WebsiteBuildResult {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents", isDirectory: true)
        let root = documents
            .appendingPathComponent("Earth Agent", isDirectory: true)
            .appendingPathComponent("Website Builder", isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        } catch {
            throw WebsiteBuilderError.cannotCreateDirectory
        }

        let index = root.appendingPathComponent("index.html")
        let styles = root.appendingPathComponent("styles.css")
        let readme = root.appendingPathComponent("README.txt")

        let style = WebsiteStyle(prompt: prompt)
        try html(prompt: prompt, style: style).write(to: index, atomically: true, encoding: .utf8)
        try css(style: style).write(to: styles, atomically: true, encoding: .utf8)
        try readmeText(style: style).write(to: readme, atomically: true, encoding: .utf8)

        NSWorkspace.shared.open(root)
        NSWorkspace.shared.open(index)
        return WebsiteBuildResult(directory: root, indexFile: index)
    }

    private func html(prompt: String, style: WebsiteStyle) -> String {
        let escapedPrompt = prompt
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")

        return """
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>Starter Website</title>
          <link rel="stylesheet" href="styles.css">
        </head>
        <body>
          <main class="page">
            <section class="hero">
              <p class="eyebrow">\(style.eyebrow)</p>
              <h1>Your Idea</h1>
              <p class="intro">\(style.heroCopy)</p>
              <div class="actions">
                <a href="mailto:hello@example.com">Contact me</a>
                <a href="#work" class="secondary">View work</a>
              </div>
            </section>

            <section class="section">
              <h2>About</h2>
              <p>Write a short paragraph about the idea, product, service, or project this website should explain.</p>
            </section>

            <section class="section" id="work">
              <h2>Selected work</h2>
              <div class="grid">
                <article>
                  <h3>Project One</h3>
                  <p>Describe the problem, your role, and the result.</p>
                </article>
                <article>
                  <h3>Project Two</h3>
                  <p>Show another strong example of your thinking and execution.</p>
                </article>
                <article>
                  <h3>Project Three</h3>
                  <p>Add proof, metrics, or a visual result when you have it.</p>
                </article>
              </div>
            </section>

            <section class="section">
              <h2>Skills</h2>
              <ul>
                <li>Digital marketing strategy and execution</li>
                <li>Content, campaigns, analytics, and growth experiments</li>
                <li>AI-assisted research, drafting, and workflow automation</li>
              </ul>
            </section>

            <section class="section note">
              <h2>Generated from your request</h2>
              <p>\(escapedPrompt)</p>
            </section>
          </main>
        </body>
        </html>
        """
    }

    private func css(style: WebsiteStyle) -> String {
        """
        :root {
          color-scheme: \(style.colorScheme);
          --ink: \(style.ink);
          --muted: \(style.muted);
          --line: \(style.line);
          --surface: \(style.surface);
          --accent: \(style.accent);
          --soft: \(style.soft);
          --page-bg: \(style.pageBackground);
        }

        * { box-sizing: border-box; }

        body {
          margin: 0;
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
          color: var(--ink);
          background: var(--page-bg);
        }

        .page {
          width: min(1040px, calc(100% - 40px));
          margin: 0 auto;
          padding: 56px 0;
        }

        .hero {
          padding: 56px;
          border: 1px solid var(--line);
          border-radius: \(style.heroRadius)px;
          background: var(--surface);
          box-shadow: \(style.heroShadow);
        }

        .eyebrow {
          margin: 0 0 12px;
          color: var(--accent);
          font-weight: 700;
          text-transform: uppercase;
          letter-spacing: .08em;
          font-size: 12px;
        }

        h1 {
          margin: 0;
          font-size: clamp(44px, 8vw, 84px);
          line-height: .92;
          letter-spacing: -0.04em;
        }

        h2 { margin: 0 0 14px; font-size: 28px; }
        h3 { margin: 0 0 8px; }
        p, li { color: var(--muted); line-height: 1.6; }

        .intro {
          max-width: 620px;
          font-size: 20px;
          margin: 24px 0 0;
        }

        .actions {
          display: flex;
          gap: 12px;
          margin-top: 28px;
        }

        a {
          display: inline-flex;
          align-items: center;
          min-height: 42px;
          padding: 0 16px;
          border-radius: 999px;
          background: var(--accent);
          color: \(style.buttonText);
          text-decoration: none;
          font-weight: 700;
        }

        a.secondary {
          background: var(--soft);
          color: var(--accent);
        }

        .section {
          margin-top: 28px;
          padding: 32px;
          border: 1px solid var(--line);
          border-radius: 18px;
          background: \(style.sectionBackground);
        }

        .grid {
          display: grid;
          grid-template-columns: repeat(3, 1fr);
          gap: 14px;
        }

        article {
          border: 1px solid var(--line);
          border-radius: 14px;
          padding: 18px;
          background: #fff;
        }

        .note {
          background: var(--soft);
        }

        @media (max-width: 760px) {
          .hero { padding: 34px; }
          .grid { grid-template-columns: 1fr; }
          .actions { flex-direction: column; }
        }
        """
    }

    private func readmeText(style: WebsiteStyle) -> String {
        """
        Earth Agent created this starter website.

        Style selected: \(style.name)

        Files:
        - index.html: page content
        - styles.css: visual design

        Next steps:
        1. Replace "Your Idea" with the real name of the idea, product, or project.
        2. Replace the cards with real details.
        3. Replace hello@example.com with a real contact email if you want one.
        4. Open index.html in a browser to preview changes.
        5. Ask Earth to regenerate with a style: simple, modern, dark, or startup-style.
        """
    }
}

private struct WebsiteStyle {
    let name: String
    let eyebrow: String
    let heroCopy: String
    let colorScheme: String
    let ink: String
    let muted: String
    let line: String
    let surface: String
    let accent: String
    let soft: String
    let pageBackground: String
    let sectionBackground: String
    let buttonText: String
    let heroRadius: Int
    let heroShadow: String

    init(prompt: String) {
        let lowered = prompt.lowercased()
        if lowered.contains("dark") {
            name = "Dark"
            eyebrow = "Starter website"
            heroCopy = "A focused dark website for your idea, project, or product story."
            colorScheme = "dark"
            ink = "#f7fafc"
            muted = "#a7b0be"
            line = "#2b3443"
            surface = "#111827"
            accent = "#38bdf8"
            soft = "#102033"
            pageBackground = "linear-gradient(180deg, #06080d 0%, #111827 100%)"
            sectionBackground = "rgba(17, 24, 39, .86)"
            buttonText = "#061019"
            heroRadius = 18
            heroShadow = "0 24px 80px rgba(0, 0, 0, 0.28)"
        } else if lowered.contains("startup") {
            name = "Startup-style"
            eyebrow = "Startup website"
            heroCopy = "A sharp startup-style website that explains the product, proof, and next action."
            colorScheme = "light"
            ink = "#121212"
            muted = "#525866"
            line = "#e5e7eb"
            surface = "#ffffff"
            accent = "#0f9f6e"
            soft = "#ecfdf5"
            pageBackground = "linear-gradient(180deg, #fbfdfb 0%, #edf7f1 100%)"
            sectionBackground = "rgba(255,255,255,.9)"
            buttonText = "#ffffff"
            heroRadius = 16
            heroShadow = "0 20px 70px rgba(15, 159, 110, 0.12)"
        } else if lowered.contains("simple") {
            name = "Simple"
            eyebrow = "Starter website"
            heroCopy = "A simple, readable website for your idea, project, or product."
            colorScheme = "light"
            ink = "#1f2937"
            muted = "#667085"
            line = "#e4e7ec"
            surface = "#ffffff"
            accent = "#111827"
            soft = "#f2f4f7"
            pageBackground = "#f8fafc"
            sectionBackground = "#ffffff"
            buttonText = "#ffffff"
            heroRadius = 12
            heroShadow = "0 12px 36px rgba(15, 23, 42, 0.06)"
        } else {
            name = "Modern"
            eyebrow = "Starter website"
            heroCopy = "A clear, modern website for your product, service, or story."
            colorScheme = "light"
            ink = "#15171a"
            muted = "#5f6875"
            line = "#dfe4ea"
            surface = "#ffffff"
            accent = "#1677ff"
            soft = "#eef6ff"
            pageBackground = "linear-gradient(180deg, #f7fafc 0%, #edf3f8 100%)"
            sectionBackground = "rgba(255,255,255,.82)"
            buttonText = "#ffffff"
            heroRadius = 24
            heroShadow = "0 24px 80px rgba(15, 23, 42, 0.08)"
        }
    }
}
