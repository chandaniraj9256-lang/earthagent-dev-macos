# Security Policy

Earth Agent is early beta and includes foundations for AI providers, voice providers, local memory, logs, Accessibility automation, and connector setup. Please treat security and privacy issues seriously.

## Supported Versions

Security fixes target the current `main` branch.

## Reporting A Vulnerability

Please do not open a public issue for a vulnerability that exposes secrets, private data, or unsafe automation behavior.

Report privately through GitHub Security Advisories if available for the repository. If that is not available, open a minimal public issue that says a private security report is needed, without including exploit details or secrets.

## Sensitive Areas

- API key storage and Keychain behavior.
- Provider request logging.
- Voice provider credentials.
- Clipboard, screenshot, and file attachment handling.
- Local memory and logs.
- Accessibility permissions.
- Computer-use actions such as click, type, shortcut, scroll, post, send, purchase, delete, or account changes.
- Social connector tokens and delivery flows.

## Safety Expectations

Earth Agent should not:

- Hardcode API keys.
- Log API keys or tokens.
- Store secrets in local memory.
- Send messages, publish posts, purchase items, delete files, or change accounts without final confirmation.
- Bypass macOS security prompts.
- Use Accessibility permissions in a hidden or malware-like way.
