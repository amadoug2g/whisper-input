# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.0.x   | ✅        |
| < 1.0   | ❌        |

## Reporting a Vulnerability

If you discover a security vulnerability in Memo, please report it responsibly:

1. **Do not** open a public issue
2. Email: [create a private security advisory](https://github.com/amadoug2g/whisper-input/security/advisories/new)
3. Include: description, reproduction steps, impact assessment

## Security Design

- **API keys** are stored in the macOS Keychain (`kSecAttrAccessibleWhenUnlocked`), never on disk or in UserDefaults
- **Network sessions** are ephemeral (`URLSessionConfiguration.ephemeral`) — no cookies, no disk cache
- **Audio files** are written to `NSTemporaryDirectory` and not persisted
- **Sandbox** is enforced via entitlements (microphone + network client only)
- **No third-party dependencies** — pure Swift + system frameworks
