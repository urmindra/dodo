# Dodo

Native macOS notes and tasks. Markdown notes, time-bucketed tasks, a menu-bar extra, and a full window. Local SwiftData. No iCloud, meetings, or LLM in v0.

Spec: [`docs/superpowers/specs/2026-08-28-dodo-v0-design.md`](docs/superpowers/specs/2026-08-28-dodo-v0-design.md)

## Requirements

- macOS 15 or later
- Xcode 16 or later (to open and run the app)
- Swift 6 (Command Line Tools are enough for `DodoCore` package tests)

## Open in Xcode

1. Clone this repository.
2. Open `Dodo.xcodeproj`.
3. Select the **Dodo** scheme and **My Mac**.
4. Press ⌘R to run.

The first launch creates `~/Library/Application Support/Dodo/Dodo.json`.

## Tests

DodoCore (no Xcode.app required):

```bash
swift test --package-path Packages/DodoCore
```

App scheme (requires Xcode):

```bash
xcodebuild test -project Dodo.xcodeproj -scheme Dodo -destination 'platform=macOS'
```

## Layout

- `Packages/DodoCore` — records, stores, search, settings keys, JSON library snapshot
- `Dodo` — SwiftUI windows, menu bar extra, Settings
- `DodoTests` — app-host unit tests

## License

Private for now.
