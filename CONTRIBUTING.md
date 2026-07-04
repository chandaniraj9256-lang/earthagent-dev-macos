# Contributing To Earth Agent

Thanks for helping build Earth Agent. The project needs product-minded SwiftUI engineers, agent builders, voice/audio contributors, safety reviewers, documentation writers, and testers.

## Good First Contributions

- Improve README setup clarity.
- Add provider model catalog entries.
- Improve provider connection tests.
- Add voice provider support.
- Polish SwiftUI views and accessibility labels.
- Add planner and safety tests.
- Improve error messages.
- Improve docs for permissions, Keychain, and setup.

## Local Setup

```bash
git clone https://github.com/chandaniraj9256-lang/earthagent-dev-macos.git
cd earthagent-dev-macos
swift build
swift run EarthAgent
```

Build the macOS app bundle:

```bash
./Scripts/build_app.sh
```

Run the release smoke test:

```bash
./Scripts/release_smoke_test.sh
```

## Pull Request Checklist

- Keep changes focused.
- Run `swift build`.
- Run relevant scripts in `Scripts/` when touching planner, streaming, speech cleanup, clipboard, notes, packaging, or safety behavior.
- Do not commit API keys, tokens, private logs, screenshots with secrets, or personal user data.
- Update README or docs when behavior changes.
- Keep high-risk automation behind confirmation.

## Product Principles

- The user stays in control.
- Sensitive actions require confirmation.
- Local memory is opt-in.
- API keys belong in Keychain, not source files or logs.
- UI should feel calm, modern, and understandable to non-technical users.

## Areas That Need Care

- Accessibility automation.
- Voice conversation loops.
- Provider request/response parsing.
- Screen capture and private data handling.
- Social connectors and external message sending.
- Any action that types, clicks, posts, sends, purchases, deletes, or changes accounts.
