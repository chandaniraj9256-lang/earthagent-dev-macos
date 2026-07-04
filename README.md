# Earth Agent

Earth Agent is a macOS SwiftUI foundation for a voice-first AI desktop assistant. It creates a small animated floating Earth icon near your cursor. Single-clicking the icon opens a compact assistant window; double-clicking opens it and starts live listening. The app includes chat, voice controls, global shortcuts, provider settings, file/photo upload, screen capture, task planning, safety controls, routines, a 30-agent swarm system, memory, logs, social connector setup, and a visual AI cursor foundation.

Earth Agent is open source under the MIT License. The goal is to build a practical, safe, voice-first AI assistant for macOS in public, with room for contributors to improve providers, voice, automation, safety, UI polish, and agent skills.

This is the first production-grade foundation, not the final autonomous computer-control product. It is designed so the next versions can add deeper Accessibility-driven UI reading, controlled clicking, memory, tool plugins, and signed app packaging without rewriting the core.

## What Works Now

- Floating Earth icon that stays above other windows and follows near the real cursor.
- Single-click the Earth icon to open a modern floating AI minibar.
- Double-click the Earth icon to start listening immediately.
- Global shortcuts:
  - `Control+Option+Space` starts listening, or stops Earth if it is already active.
  - `Control+Option+M` opens the minibar.
  - `Control+Option+L` captures the screen and asks Earth to explain what it sees.
- Optional `Start Earth Agent at login` toggle in Settings, using Apple's safe Login Items API.
- Minibar controls:
  - Earth/status dot shows current state.
  - Text field lets you type a command.
  - Mic button converts speech into text.
  - Waveform button starts conversation mode for back-and-forth voice chat.
  - Expand button opens the full chat and settings window.
  - Stop button immediately stops Earth.
- Full assistant window tabs: `Chat`, `Tasks`, `Agents`, `Memory`, `Settings`, `Safety`, and `Logs`.
- New `Tasks` tab with structured plan details: intent, tools, risk, confirmation, expected result, fallback, timeline, browser results, and local file actions.
- New `Tasks` prompt queue so commands typed while Earth is working are saved and run next instead of being lost.
- New `Tasks` tool registry showing each action's risk level, permission requirement, status, and confirmation policy.
- New `Agents` tab with routines, built-in skills, a 30-agent swarm catalog, MCP connector setup, social connector setup, and advanced computer-use status.
- New `Memory` tab with opt-in categorized memory, edit/delete controls, and local session search.
- New `Logs` tab with local transparency/audit entries.
- Full chat includes quick skill cards for common tasks.
- Full chat now has a polished product shell with readiness indicators for provider, model, connection, and voice.
- First-run setup guidance appears when the provider key or connection test is missing.
- Action preview appears before task execution, with confirmation for guarded actions.
- Safety modes: Chat only, Draft only, Ask before actions, and Autopilot for safe actions.
- Local memory is opt-in. Earth remembers only what you explicitly save or say with "remember".
- Provider setup includes a connection test plus live model refresh.
- Text chat through an OpenAI-compatible `/chat/completions` provider.
- Typed chat now streams the assistant reply as it arrives when the provider supports OpenAI-style streaming, with automatic fallback to the stable full-response path.
- File upload from the chat composer: photos, videos, documents, and general files.
- Drag-and-drop files into the chat window.
- Small PDFs now contribute extracted text preview to the AI context instead of only file metadata.
- Screen capture button in the composer.
- `Look at my screen` command captures the current screen and sends it to vision-capable models when supported.
- `Summarize my clipboard`, `Explain the copied text`, and `Copy your last answer` use the clipboard only after you explicitly ask.
- `Save your last answer as a note` writes Earth's latest reply to `Documents/Earth Agent/Notes`; `List my saved notes` shows recent note files; `Read note 1` shows a listed note in chat; `Open note 1` opens it; `Open my Earth Agent notes folder` opens that folder later.
- `Show launch readiness report`, `Export diagnostics report`, and `Open diagnostics folder` turn the beta-readiness checklist into chat commands instead of burying it in Settings.
- Small photos are sent as vision-ready image inputs to compatible OpenAI-style providers, with text-only fallback if the provider rejects image input.
- Provider settings for provider name, model name, base URL, and API key.
- API key storage in macOS Keychain.
- Push-to-talk voice input foundation using Apple Speech recognition.
- Spoken assistant replies using macOS text-to-speech or a configured external voice provider.
- Live Talk uses a dedicated short-answer voice prompt, temporary session context, streaming text when the provider supports it, cleaner spoken text, configurable turn timing, and interruptible speech.
- Voice diagnostics split health into microphone, speech-to-text, AI model, text-to-speech, playback, and interruption.
- Status states: Listening, Thinking, Working, Waiting for confirmation, Task completed, Task failed, Paused, Stopped.
- Agent planner structure that classifies requests into chat, drafting, browser/search, app opening, UI inspection, computer control, memory, routine, sensitive, or unsupported categories.
- Structured risk levels: Low, Medium, High. High-risk requests are never executed automatically.
- Safe automation examples:
  - Open Google, YouTube, Safari, Chrome, or a website URL.
  - Search Google.
  - Draft text without publishing.
- Visual second cursor placeholder during tasks.
- Emergency Stop and Pause controls.
- Real mouse movement pauses AI task execution.
- Local action logs with a delete button.
- Permission and safety screen.
- Local routines foundation. Routines can be enabled and Earth asks before running them. Routines now keep provider/model/toolset metadata so scheduled work is more predictable.
- Built-in skills foundation inspired by Hermes-style `SKILL.md` packages. Current skills are read-only and bundled into the app.
- Internal 30-agent swarm foundation. Earth can split a long task into specialist perspectives, run a focused squad in parallel, show live progress, and synthesize the briefs into one safe next step.
- MCP connector foundation. Connector settings and enabled-tool metadata are visible locally, with explicit permission required before any future external tool action.
- Social connector foundation for Telegram, WhatsApp, Slack, Discord, and Email. Tokens are saved in Keychain, and external sending remains blocked behind confirmation.
- Advanced computer-use report with active app, running apps, visible windows, capability status, safe app focus, confirmed scrolling, and hard blocks for dangerous shortcuts/typed shell text.
- Local website generator with simple, modern, dark, and startup-style variants.

## What Is Intentionally Still TODO

- OCR and deeper screen understanding beyond screenshot-based vision.
- Full autonomous browser navigation across arbitrary websites.
- Full final confirmation flows for posting, sending messages, purchases, deletes, or account changes.
- Live social gateway delivery for Telegram/WhatsApp/Slack/Discord/Email. The setup UI and Keychain storage exist now; real message delivery needs provider-specific webhook/OAuth implementation.
- Notarization and automatic updates.

Those are product layers. The current project creates the architecture and safety boundaries first.

## Requirements

- macOS 13 or newer.
- Xcode Command Line Tools or Xcode installed.
- An API key from an OpenAI-compatible provider.

Check Swift:

```bash
swift --version
```

## Run The App

From this folder:

```bash
swift build
swift run EarthAgent
```

When it starts, you should see a small animated Earth icon following near your cursor. Single-click it to open the minibar, double-click it to start live listening, or press `Control+Option+Space` from anywhere to talk/stop.

To stop the app from Terminal, press:

```bash
Control+C
```

## Build A Real Mac App

When you want Earth Agent to appear as a normal macOS app:

```bash
./Scripts/build_app.sh
```

This creates:

```text
dist/Earth Agent.app
```

To install it into Applications:

```bash
./Scripts/install_app.sh
```

Then open it from Applications, Launchpad, or:

```bash
open "/Applications/Earth Agent.app"
```

After installing, open `Settings > App behavior` and enable `Start Earth Agent at login` if you want Earth available automatically after restart. If macOS asks for approval, open `System Settings > General > Login Items` and allow Earth Agent.

## Configure AI

1. Click the floating Earth icon.
2. Click `+` in the minibar.
3. Open the `Settings` tab.
4. Choose a provider from the dropdown.
5. Paste your API key.
6. Click `Save`.
7. Click `Test` to confirm the provider works.
8. Click `Models` to load the provider's current model list.
9. Choose the model from the model dropdown.

The API key is saved in macOS Keychain. It is not saved in the project and is not written to logs.

### Provider Examples

OpenAI:

```text
Provider name: OpenAI
Model name: gpt-4o-mini
Base URL: https://api.openai.com/v1
```

NVIDIA:

```text
Provider name: NVIDIA NIM
Model name: nvidia/llama-3.3-nemotron-super-49b-v1.5
Base URL: https://integrate.api.nvidia.com/v1
```

The NVIDIA dropdown includes fallback Nemotron/NIM IDs such as:

```text
nvidia/nemotron-3-ultra-550b-a55b
nvidia/nemotron-3-super-120b-a12b
nvidia/nemotron-3-nano-30b-a3b
nvidia/llama-3.1-nemotron-ultra-253b-v1
nvidia/llama-3.3-nemotron-super-49b-v1.5
```

NVIDIA model availability changes by account and endpoint. After saving your NVIDIA key, press `Models` to fetch the live model list available to your key.

Groq:

```text
Provider name: Groq
Model name: llama-3.1-8b-instant
Base URL: https://api.groq.com/openai/v1
```

Local OpenAI-compatible server:

```text
Provider name: Local
Model name: your-local-model-name
Base URL: http://localhost:1234/v1
```

### Model Dropdown

Earth Agent ships with fallback model names for common providers, but the better flow is live discovery:

1. Select provider.
2. Paste API key.
3. Save securely.
4. Click `Models`.
5. Select any model returned by the provider.

This uses the provider's OpenAI-style `/models` endpoint where available, and also accepts common `data`, `models`, and array response shapes. NVIDIA, Groq, OpenRouter, DeepSeek, and similar providers can update without requiring a code change.

## Voice Setup

Click `Talk` in the chat tab. macOS may ask Terminal or Earth Agent for:

- Microphone permission.
- Speech Recognition permission.

Because this foundation runs through Swift Package Manager, macOS may show the permission prompt for your Terminal app. When this becomes a signed `.app`, use `Packaging/EarthAgent-Info.plist` so macOS shows the prompt for Earth Agent itself.

In the minibar:

- Click the mic icon to dictate into the text field.
- Click the waveform icon for conversation mode. Earth Agent listens, waits for your transcript to stabilize, replies briefly, speaks back, then listens again.
- If microphone or speech permission is missing, Earth now stops cleanly and tells you exactly which macOS privacy setting needs attention.
- If a voice playback callback stalls, Earth now recovers its speaking state automatically instead of getting stuck.
- Tap the mic or waveform while Earth is speaking to interrupt and talk over it naturally.
- Click the red stop icon in conversation mode to end the live voice loop.

In the full chat bar:

- `Live Talk` starts or stops hands-free conversation.
- The voice status label shows `Listening`, `Thinking`, `Speaking`, `Interrupted`, `Paused`, `Stopped`, or `Voice issue`.
- Spoken-mode AI replies are intentionally shorter than normal chat replies.
- Open `Settings > Live Talk timing` to tune silence delay, minimum speech length, listening timeout, and macOS voice speed.

How Live Talk works:

1. Earth listens through Apple Speech recognition.
2. When your transcript stabilizes, Earth sends the text with a dedicated voice prompt.
3. If the provider supports OpenAI-style streaming, the answer appears in chat as it arrives. If not, Earth falls back to the stable standard response path.
4. The final AI answer is cleaned for speech, then spoken aloud.
5. Earth waits briefly, clears the transcript, and starts listening again.
6. If you tap mic, waveform, or Stop while Earth is speaking, speech stops immediately.

Live Talk context is temporary. It helps short follow-ups such as "both" or "continue" make sense during the current voice session, but it is not saved to permanent memory unless you explicitly ask Earth to remember something.

## Agents Tab

Click the Earth icon, press `+`, then open the `Agents` tab.

What is there:

- `Routines`: local scheduled tasks. Use the bell button to enable one, or the play button to run one now.
- `Skills`: built-in reusable workflows such as browser research, document summary, message drafting, meeting notes, website building, screen explanation, and safe automation.
- `Agent Swarm`: 30 internal specialist roles that review bigger requests before Earth acts.
- `MCP Connectors`: connector setup foundation for tools like GitHub, Linear, n8n, and custom local MCP servers.
- `Social Connectors`: setup for Telegram, WhatsApp, Slack, Discord, and Email remote approvals/notifications.
- `Advanced Computer Use`: current macOS control readiness, running apps, visible windows, and safe capabilities.

Useful commands:

```text
List routines.
Run routine 1.
Create routine to draft a Friday reflection.
Use agent swarm to review my product plan.
Use all 30 agents to review this launch plan.
MCP connector status.
Advanced computer use status.
List running apps.
Focus Chrome.
Scroll down.
```

Important: routines, connectors, clicks, typing, scrolling, posting, sending, deleting, purchases, and account changes are designed to stay under your confirmation.

## Tasks, Memory, And Logs

Open the full window with `+`.

`Tasks` shows:

- Latest interpreted intent.
- Required tools.
- Risk level.
- Confirmation status.
- Expected result.
- Fallback plan.
- Timeline of current work.
- Browser results, notes, website actions, and local automation status.

`Memory` shows opt-in local memory. Categories:

- Preferences
- Writing style
- Work context
- Project details
- App behavior

Earth blocks obvious secrets such as passwords, API keys, credit card details, and private keys from casual memory saves.

`Logs` shows the local action trail:

- User command.
- AI interpretation.
- Planned action.
- Tools used.
- Confirmation status.
- Result or error.

You can delete logs from the Logs tab or delete both memory and logs from Safety.

## Website Workflow

Try:

```text
Create a simple local website for my idea.
Create a dark local website for my project.
Create a startup-style local website for my product.
```

Earth creates local editable files in:

```text
~/Documents/Earth Agent/Website Builder/
```

## Voice API Providers

Earth can speak with the built-in macOS voice for free, or use an external voice provider for more natural speech.

Working voice providers in this build:

- `macOS System Voice`: no API key required. Earth can use installed macOS voices such as Aman, Rishi, Tara, Samantha, Daniel, Karen, and other voices available on your Mac.
- `ElevenLabs`: paste an ElevenLabs API key and voice ID.
- `OpenAI TTS`: paste an OpenAI API key and choose an OpenAI voice.

Planned providers are visible in the app so the product has a clear path, but playback is not enabled yet for them:

- Cartesia
- PlayHT
- Azure AI Speech
- Custom / local TTS gateway

To set up ElevenLabs voice:

1. Open Earth Agent.
2. Click `+`.
3. Open `Settings`.
4. In `Voice connection`, choose `ElevenLabs`.
5. Paste your ElevenLabs API key.
6. Choose or paste a voice ID.
7. Click `Save Voice`.
8. Click `Test Voice`.

Default ElevenLabs endpoint:

```text
https://api.elevenlabs.io/v1
```

To set up OpenAI voice:

1. In `Voice connection`, choose `OpenAI TTS`.
2. Paste your OpenAI API key.
3. Choose a model such as `gpt-4o-mini-tts`.
4. Choose a voice such as `alloy`, `nova`, `shimmer`, or `verse`.
5. Click `Save Voice`.
6. Click `Test Voice`.

Voice API keys are stored separately from chat AI keys in macOS Keychain. They are not written to logs.

To install more macOS voices:

1. Open macOS `System Settings`.
2. Go to `Accessibility`.
3. Open `Spoken Content`.
4. Open the `System Voice` menu.
5. Choose `Manage Voices`.
6. Download the voices you want.
7. Reopen Earth Agent and check `Settings > Voice connection`.

## Accessibility Permission

The current version can open apps and websites without Accessibility permission. UI inspection, controlled typing, keyboard shortcuts, and numbered clicking need Accessibility permission.

To enable it:

1. Open the Earth Agent `Safety` tab.
2. Click `Grant Permission`.
3. Add or enable the app/Terminal running Earth Agent.

Earth Agent should never bypass macOS security prompts.

## Try These Commands

```text
Open Chrome.
Search the web for AI automation tools.
Inspect browser.
Summarize my clipboard.
Draft a clear message. Do not send it.
Create a simple local website for my idea.
Computer control status.
What app am I using?
Inspect visible UI elements.
Click element 1.
Type this: Hello from Earth Agent.
Press command L.
Explain what you are doing.
Pause.
Stop.
Take over.
Remember that I prefer short, direct answers.
```

## Skill Cards, Memory, And Safety

Single-click the Earth icon to open the minibar, then click the expand button to open the full chat window. Double-click the Earth icon, or press `Control+Option+Space`, to start live listening.

In `Chat`, use the skill cards at the top for common tasks:

- Summarize File
- Draft Message
- Web Research
- Open App
- Inspect Browser
- Explain Screen
- Simple Website
- Control Status
- Active App
- Inspect UI
- Type Text

`Simple Website` creates real local files in:

```text
~/Documents/Earth Agent/Website Builder
```

## Computer Control Foundation

Earth Agent now has the first safe computer-use layer:

- Check Accessibility permission.
- Report the active app.
- Open browser searches.
- Inspect visible browser controls and page elements.
- Inspect visible Accessibility UI elements in the active app.
- Show numbered click targets.
- Click a numbered element only after your confirmation.
- Type text into the focused field.
- Press supported shortcuts such as `command L`, `command A`, `command C`, `command V`, `command S`, `command W`, `enter`, `escape`, and `tab`.

Clicks, typing, and shortcuts always ask for confirmation. After you confirm, Earth gives you a short countdown so you can focus the target app before it acts.

To inspect the active app:

```text
Inspect visible UI elements.
```

Earth will reply with numbered elements, for example:

```text
#1 Button: Sign In (clickable)
#2 TextField: Search (visible)
```

To click one:

```text
Click element 1.
```

Earth will ask for confirmation first. It will not publish posts, send messages, purchase anything, delete files, or change accounts without a final confirmation step.

## Browser Use Foundation

Earth can start a browser search and then inspect the visible browser page through Accessibility.

Try:

```text
Search the web for AI automation tools.
Inspect browser.
Click element 1.
Open this result.
```

`Inspect browser` labels likely results as search results, websites, documents, media, or page controls when it can infer that from visible Accessibility text.

`Click element 1` and `Open this result` always ask for confirmation first. If the page changes, run `Inspect browser` again so the numbered list is fresh.

## First-Run Readiness

Earth now shows a first-run checklist in the chat and Safety tab:

- AI provider saved in Keychain.
- Model selected and tested.
- Microphone permission for voice input.
- Speech Recognition permission for dictation and conversation mode.
- Screen Recording permission for `Look at my screen`.
- Accessibility permission for browser/UI control.
- Voice mode ready when a local or external voice provider is configured.

Click `Done` after setup to hide the first-run checklist.

Use `Safety > Permission doctor` to check permissions, request Microphone/Speech/Screen Recording access, or open the exact macOS privacy panes.
Use `Settings > Launch Readiness` to see a startup-quality scorecard for AI setup, voice, permissions, safety, background behavior, and first-run completion.
Click `Export Diagnostics` from Launch Readiness or Safety to create a redacted Markdown report in `Documents/EarthAgent Diagnostics`. It includes readiness, permission status, provider/model names, recent tasks, and recent logs without API keys.

To enable typing and keyboard control:

1. Open Earth Agent.
2. Open the full window from the minibar expand button.
3. Go to `Safety`.
4. In `Computer control`, click `Grant Permission`.
5. Enable Earth Agent or Terminal in macOS Accessibility settings.

In `Safety`, choose how much control Earth has:

- `Chat only`: no external actions.
- `Draft only`: drafts only, no opening apps/websites.
- `Ask before actions`: asks before opening apps or websites.
- `Autopilot for safe actions`: can open apps/websites, still asks before sensitive actions.

In `Safety > Memory`, save preferences manually. Example:

```text
I prefer short, direct answers with a quick summary first.
```

You can also type:

```text
Remember that I prefer concise answers.
```

## Project Structure

```text
Package.swift
README.md
Packaging/
  EarthAgent-Info.plist
  EarthAgent.entitlements
Sources/EarthAgent/
  EarthAgentApp.swift
  AppDelegate.swift
  AppServices.swift
  AppModel.swift
  Models/
  Services/
  Views/
  Windows/
```

Important files:

- `AppModel.swift`: central app state, chat flow, status changes, stop/pause, task execution.
- `Services/OpenAICompatibleClient.swift`: OpenAI-compatible chat calls, streaming SSE parsing, and non-streaming fallback.
- `Services/VoicePromptBuilder.swift`: dedicated Live Talk system prompt and temporary session context.
- `Services/SpokenTextCleaner.swift`: removes markdown, code, links, tables, and emoji-like symbols before speech.
- `Services/KeychainService.swift`: secure API key storage.
- `Services/AgentPlanner.swift`: structured planner with category, tools, risk level, confirmation, expected result, and fallback.
- `Services/AutomationService.swift`: safe macOS automation examples.
- `Services/ComputerControlService.swift`: Accessibility checks, app/window status, UI inspection, confirmed typing/clicking/scrolling.
- `Services/RoutineStore.swift`: local routine scheduling foundation.
- `Services/SubagentCoordinator.swift`: 30-agent swarm selection, specialist prompts, and synthesis.
- `Services/MCPConnectorStore.swift`: local MCP connector foundation.
- `Windows/FloatingEarthWindowController.swift`: floating Earth icon window.
- `Windows/CursorOverlayWindowController.swift`: visual AI cursor overlay.
- `Views/ChatPanelView.swift`: full assistant window with Chat, Tasks, Agents, Memory, Settings, Safety, and Logs tabs.

## Screenshots

Screenshots should be added before public launch:

- Floating Earth orb near cursor.
- Minibar with text, mic, and live conversation controls.
- Chat tab with onboarding and quick skills.
- Tasks tab with risk/plan/timeline.
- Agents tab with routines, 30-agent swarm, connectors, and computer-use status.
- Settings tab with provider and voice setup.
- Safety tab with control level and permissions.

## Build Verification

For a quick development compile check:

```bash
swift build
```

For the full release smoke test:

```bash
./Scripts/release_smoke_test.sh
```

That command verifies planner safety routing, streaming response parsing, spoken text cleanup, clipboard read/write behavior, note writing, debug build, production app bundle creation, required plist privacy descriptions, code signing, install into `/Applications`, and installed app signature.

To run only the fast checks:

```bash
./Scripts/planner_safety_tests.sh
./Scripts/streaming_client_tests.sh
./Scripts/spoken_text_cleaner_tests.sh
./Scripts/clipboard_service_tests.sh
./Scripts/note_writer_tests.sh
```

For the manual installed app flow, use:

```bash
./Scripts/build_app.sh
./Scripts/install_app.sh
open "/Applications/Earth Agent.app"
```

## Roadmap

1. Convert the Swift Package into a signed Xcode `.app` target using the included `Packaging` plist and entitlements.
2. Add notarization, auto-updates, and a proper DMG installer.
3. Add a formal tool registry around current services.
4. Add deeper browser automation with visual element overlays.
5. Add screen OCR with a privacy-first Screen Recording permission flow.
6. Add live provider-specific model/voice catalog refresh for more providers.
7. Add local encrypted memory storage.
8. Add tests for planner routing, provider request encoding, memory filtering, and safety confirmation rules.
9. Add real MCP execution with per-tool permissions after connector safety UX is mature.
10. Add screenshots, product website, support docs, and beta onboarding.


## Contributing

Contributions are welcome. Good first areas:

- Provider model catalogs and connection tests.
- Voice provider integrations.
- SwiftUI polish and accessibility.
- Safer automation tools with clear confirmation steps.
- Tests for planning, safety, memory, and provider behavior.

Please keep secrets out of commits. API keys belong in macOS Keychain or local environment variables, never in source files.

## License

Earth Agent is released under the MIT License. See [LICENSE](LICENSE).
