# Hermes Agent Feature Audit for Earth Agent

Date: 2026-07-03

Sources checked:

- Official repo: https://github.com/NousResearch/hermes-agent
- Official docs: https://hermes-agent.nousresearch.com/docs/
- Local inspection clone: `/tmp/hermes-agent`
- License: MIT

## Summary

Hermes Agent is broader than Earth Agent today. It is an open-source agent platform with CLI, desktop, messaging gateway, skills, memory, session search, MCP, scheduled work, toolsets, subagents, voice, and computer-use integrations.

Earth Agent should not copy Hermes directly. Earth Agent's advantage should be a premium native macOS voice-first desktop assistant: floating Earth, minibar, beautiful status UI, spoken conversation, safe confirmations, visible AI cursor, and native Accessibility automation.

The right strategy is to borrow Hermes' architecture patterns and rebuild them in Swift/macOS style.

## Highest-Value Hermes Features To Borrow

### 1. Tool Registry and Toolsets

Hermes has a formal tool registry. Tools declare name, schema, handler, availability checks, required environment, toolset, and result limits. Toolsets can be enabled or disabled by platform.

Earth Agent currently routes many actions through `AgentPlanner`, `AppModel`, and separate services. That works for a foundation, but it will get messy as actions grow.

Implement in Earth Agent:

- `AgentTool` protocol.
- `AgentToolRegistry`.
- `AgentToolset`.
- Tool metadata: title, description, required permission, risk level, confirmation policy.
- Standard result envelope: success, message, data, error, redacted diagnostics.
- Progress events for the right-side task timeline.
- Availability checks for Accessibility, Screen Recording, microphone, provider, model, and Keychain secrets.

First tools to migrate:

- `open_app`
- `open_website`
- `search_web`
- `inspect_ui`
- `open_browser_result`
- `click_element`
- `type_text`
- `summarize_clipboard`
- `look_at_screen`
- `create_website`
- `run_agent_swarm`

Why this improves Earth Agent:

- Fewer bugs from giant switch statements.
- Cleaner confirmations.
- Easier plugin/MCP support later.
- Better UI because every tool can report status the same way.

### 2. Skills System

Hermes uses `SKILL.md` packages with progressive disclosure. The agent sees short skill metadata first, then loads full instructions only when needed. Skills can include references, scripts, templates, assets, platform limits, required config, and required secrets.

Earth Agent should add read-only skills first. Do not start with self-editing skills.

Implement in Earth Agent:

- Skills folder:
  `~/Library/Application Support/Earth Agent/Skills/`
- Built-in skills bundled in the app.
- `SkillPackage` model with name, description, version, category, platform, required tools, required permissions.
- `SkillLoader` that parses frontmatter and reads `SKILL.md`.
- Skill picker in the Agents tab.
- Skill cards in chat.
- Natural-language routing from planner to matching skills.
- Optional scripts later, only after sandboxing and approval UI.

Good first public skills:

- Browser research
- Document summary
- Meeting notes
- Email/message drafting
- Website builder
- Screen explanation
- Mac troubleshooting
- App setup checklist
- Travel planning
- Study helper

Why this improves Earth Agent:

- New workflows can be added without bloating the core app.
- Founder/non-coder users can understand skills as "things Earth knows how to do."
- It creates a future marketplace path.

### 3. Session Search and Recall

Hermes has persistent memory plus session search. Memory stores compact important facts; session search finds old conversations on demand.

Earth Agent currently has local memory and logs, but not full conversation recall.

Implement in Earth Agent:

- Local SQLite store for conversations, tasks, tool calls, approvals, and attachments metadata.
- Full-text search using SQLite FTS5.
- "Search past chats" in Memory tab.
- "Continue previous task" from minibar.
- Session summaries for long chats.
- Memory remains small and curated; session search handles the rest.

Why this improves Earth Agent:

- Less need to stuff everything into memory.
- Better continuity across days.
- Users can ask "what did we decide yesterday?".

### 4. Bounded Memory With Approval

Hermes separates user profile memory from agent/environment memory, keeps memory bounded, and can require approval before memory writes.

Earth Agent should improve its memory model:

- Separate `UserPreferences` from `AgentLessons`.
- Add source and timestamp to every memory.
- Add "why this was remembered."
- Add pending memory approval queue.
- Add prompt-injection and secret scanning before memory is used.
- Add memory export/delete.

Why this improves Earth Agent:

- Safer personalization.
- More trust.
- Less "creepy assistant" feeling.

### 5. Scheduled Routines With Safe Execution

Hermes has cron jobs with create/list/update/pause/resume/run/remove, attached skills, delivery targets, no-agent script mode, model pinning, and safeguards against runaway scheduled jobs.

Earth Agent should build a smaller native Mac version:

- Local routine list.
- Pause/resume/run now/edit/delete.
- Attached skill.
- Attached toolset.
- Pinned provider/model for each routine.
- Local notification when done.
- "Approval required before external action" flag.
- No unattended sending, posting, purchasing, deleting, or account changes.

Good first routines:

- Morning brief
- Daily file summary
- Weekly project review
- Reminder to follow up
- Check website status
- Summarize clipboard or selected note

Why this improves Earth Agent:

- Makes the app useful even when the user is not actively chatting.
- Creates recurring value, which is important for paid retention.

### 6. MCP Connector Catalog With Tool Filtering

Hermes supports MCP servers and lets users filter which tools each server exposes. This is important because many MCP servers expose dangerous or noisy tools.

Earth Agent already has an MCP connector foundation, but it should become more concrete.

Implement in Earth Agent:

- Connector catalog UI.
- Local stdio MCP first.
- HTTP MCP later.
- Keychain-backed secrets.
- Per-server enable/disable.
- Per-tool enable/disable checklist.
- Risk badge per exposed tool.
- "Test connector" button.
- Tool results routed through the same `AgentToolRegistry`.

Good first connector targets:

- Filesystem, scoped to a user-selected folder.
- GitHub.
- Linear.
- Notion.
- Google Drive.
- Local custom MCP server.

Why this improves Earth Agent:

- Users can extend Earth safely without waiting for us to build every integration.
- Tool filtering prevents clutter and reduces risk.

### 7. Subagent Progress UI

Hermes desktop tracks subagent status, task count, current tool, streamed progress, files read/written, duration, token/cost fields, and summaries.

Earth Agent has a 30-agent swarm, but the UI should show live progress instead of only a final result.

Implement in Earth Agent:

- `SubagentRunEvent`.
- Live swarm timeline.
- Per-agent status: queued, running, blocked, completed, failed.
- Current action/tool label.
- Short streamed notes.
- Final summary per agent.
- Combined synthesis.
- Stop/pause all agents.
- Cost/token estimates when provider returns usage.

Why this improves Earth Agent:

- Makes long tasks feel alive and trustworthy.
- Helps users understand why the app is taking time.

### 8. Prompt Queue While Busy

Hermes desktop has a composer queue so prompts are not lost while a session is running or reconnecting.

Earth Agent should add:

- Queue typed prompts while Earth is working.
- Show "1 queued" above minibar.
- Allow edit/delete/promote queued prompts.
- Run next prompt automatically after the current task finishes unless user paused.

Why this improves Earth Agent:

- Makes the app feel smoother.
- Prevents the user from thinking it ignored their message.

### 9. Better Voice Pipeline Diagnostics

Hermes treats voice as separate STT, TTS, playback, and platform flows.

Earth Agent already has macOS voice, ElevenLabs, and OpenAI TTS foundations. It should make voice more debuggable:

- Separate STT provider settings from TTS provider settings.
- Add voice latency test.
- Add mic level meter.
- Add conversation-mode health card.
- Show exact failing layer: mic, speech recognition, LLM, TTS, playback.
- Add local Whisper later.
- Add Groq/OpenAI/ElevenLabs STT options.
- Add more TTS providers only after the current flow is reliable.

Why this improves Earth Agent:

- The user asked for smoother voice. Debug visibility is how we get there.

### 10. Safer Computer Use

Hermes' computer-use skill describes a strong workflow: capture first, click by element index, verify after action, and never interact with sensitive UI without explicit user instruction.

Earth Agent should keep native macOS Accessibility, but copy the workflow:

- Capture/inspect first.
- Show numbered elements.
- Let user confirm by number.
- Move AI cursor before action.
- Perform action.
- Re-inspect/verify.
- Log every step.

Do not import Hermes' cross-platform computer-use implementation into Earth Agent yet. Native Swift/macOS will feel better and integrate with the floating cursor.

## What Earth Agent Should Not Copy

- Do not add a heavy Python runtime as the default app engine.
- Do not expose 60+ tools on day one.
- Do not build every messaging platform before the Mac app feels great.
- Do not add self-modifying skills until approvals, backups, and review UI are mature.
- Do not enable remote/browser/computer tools without clear permission screens.

## Recommended Earth Agent Roadmap

### Phase 1: Reliability and Polish

- Prompt queue.
- Cleaner voice diagnostics.
- Better error cards.
- Provider/model health cards.
- Better task progress timeline.
- Ship a clean installer flow.

### Phase 2: Tool Registry

- Add `AgentToolRegistry`.
- Migrate existing actions.
- Standardize progress, confirmation, and error handling.
- Show tools in Safety tab.

### Phase 3: Skills v1

- Add local read-only skills.
- Add built-in public skills.
- Add skill picker.
- Add skill cards.

### Phase 4: Session Search and Memory Approval

- SQLite conversation archive.
- FTS5 search.
- Continue previous task.
- Pending memory approvals.

### Phase 5: Routines v1

- Local scheduled routines.
- Pinned provider/model.
- Attached skill/toolset.
- Approval-required external actions.

### Phase 6: MCP Catalog

- Local MCP connector catalog.
- Per-tool filtering.
- Keychain secrets.
- Risk badges.

### Phase 7: Advanced Computer Use

- Capture-first workflow.
- Numbered overlay.
- Verify-after-action.
- Stronger sensitive UI detection.

## Top 5 Features To Implement Next

1. Prompt queue while Earth is busy.
2. Live subagent swarm progress UI.
3. `AgentToolRegistry` with risk/permission/confirmation metadata.
4. Local skills v1 using `SKILL.md`.
5. Session search with SQLite FTS5.

These five features directly reduce the "buggy" feeling, make long tasks understandable, and move Earth Agent toward a real public product without turning it into a clone of Hermes.
