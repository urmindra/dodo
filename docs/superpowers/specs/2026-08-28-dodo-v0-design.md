# Dodo v0 Design

Dodo is a native macOS notes-and-tasks app: markdown notes with tags, categories, and URL attachments; tasks in explicit time buckets; a full window plus a menu-bar extra for quick capture. Data stays local. Meetings, iCloud, local LLMs, and Claude are later phases; v0 IDs and the task–note link are the extension points.

## Goals

- Capture notes in markdown with title, body, tags, one category, timestamps, and URL attachments.
- Capture tasks with status, bucket, priority, optional due date, optional linked note, and optional detail.
- Attach tasks to notes and inspect linked tasks from a note.
- Search notes, tasks, tags, categories, and URL strings in-app.
- Capture a note or task from the menu bar without opening the main window.
- Configure editor font, note templates, categories, and priority display labels in Settings.
- Ship as a SwiftUI macOS 15+ app with a testable `DodoCore` package, GitHub issues/PRs, and CI.

## Non-goals (v0)

- Meeting recording or transcription.
- iCloud / CloudKit sync (models must remain CloudKit-ready: unique `UUID` on every entity).
- Ollama, OpenRouter, or any local LLM digest.
- Claude, MCP, or in-app chat.
- Nested folders (category + tags are the v0 organization).
- iOS UI (share `DodoCore` later; no iPhone screens now).
- Notarized distribution, App Store, Sparkle.
- Spotlight importer.
- Nested checklists, wiki links, or a custom markdown engine beyond Foundation `AttributedString` markdown plus a plain-text editor.

## Architecture

Two targets:

- **`DodoCore`** — Swift package. SwiftData schema, stores, search, settings keys. No windows, no SwiftUI scenes. Unit-tested with Swift Testing.
- **`Dodo`** — macOS app target. `WindowGroup` main window, `MenuBarExtra`, `Settings` scene, HIG chrome, markdown editor UI. Depends on `DodoCore`.

Persistence is a local SwiftData store under Application Support (`Dodo/Dodo.store`). Tests use an in-memory `ModelContainer`.

```
MenuBarExtra ─┐
Main window  ─┼─► NoteStore / TaskStore / SearchIndex ─► SwiftData models
Settings     ─┘         AppSettings (UserDefaults keys)
```

Apple Human Interface Guidelines and standard SwiftUI Mac patterns (`NavigationSplitView`, `Settings`, `MenuBarExtra`, SF Symbols). Do not use dopod-design-carbon, Electron, or Tauri.

Minimum OS: macOS 15.

## Domain model

Every entity has a unique `id: UUID` generated at insert. `createdAt` / `updatedAt` are `Date`. Stores bump `updatedAt` on every successful mutation.

### Note

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | Unique, immutable after insert |
| `title` | `String` | Trimmed; empty title is allowed and displays as “Untitled” |
| `bodyMarkdown` | `String` | Source of truth for the note body |
| `createdAt` | `Date` | Set on insert |
| `updatedAt` | `Date` | Set on insert and every mutation |
| `category` | `Category?` | At most one |
| `tags` | `[Tag]` | Many; order is insertion order |
| `links` | `[NoteLink]` | URL attachments |
| `tasks` | `[TaskItem]` | Inverse of `TaskItem.note` |

### Tag

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | |
| `name` | `String` | Unique, case-insensitive; stored trimmed; empty names are rejected |

Tags are shared across notes. Creating a note tag with an existing name (case-insensitive) reuses the existing `Tag`. Unused tags are not auto-deleted in v0.

### Category

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | |
| `name` | `String` | Unique, case-insensitive; stored trimmed; empty names are rejected |

User-defined list, managed in Settings. Notes and tasks may each have one category. Deleting a category nulls `category` on related notes and tasks; it does not delete those records.

### NoteLink

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | |
| `url` | `String` | Trimmed; must be a non-empty absolute URL with scheme `http`, `https`, or `file` |
| `label` | `String?` | Optional display label; empty string is stored as `nil` |
| `note` | `Note?` | Owner |

Invalid URLs are rejected by the store, not silently stored.

### TaskItem

The SwiftData type is `TaskItem` because `Task` collides with Swift concurrency. UI copy says “Task”.

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | |
| `title` | `String` | Trimmed; empty title is rejected |
| `detail` | `String` | Free text, may be empty |
| `status` | `TaskStatus` | `todo` \| `inProgress` \| `done` \| `waitingFollowup` |
| `bucket` | `TaskBucket` | `inbox` \| `today` \| `nextDay` \| `thisWeek` \| `thisMonth` |
| `priority` | `TaskPriority` | `none` \| `low` \| `medium` \| `high` |
| `createdAt` | `Date` | |
| `updatedAt` | `Date` | |
| `dueOn` | `Date?` | Calendar date; optional; independent of bucket |
| `note` | `Note?` | Optional link |
| `category` | `Category?` | Optional, same Category list as notes |

**Bucket rules:** buckets are explicit user-assigned destinations, not computed from `dueOn`. Any task may move to any bucket. Creating a task without a bucket uses `inbox`.

**Status transitions:** all four statuses are reachable from any other. v0 does not enforce a state machine beyond storing the enum.

### NoteTemplate

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | |
| `name` | `String` | Trimmed; empty names are rejected |
| `bodyMarkdown` | `String` | May be empty |

Templates do not auto-fill title. Applying a template to a note:

- If the note body is empty (whitespace only), replace body with the template body.
- If the note body is non-empty, append a blank line then the template body.
- Always bump `updatedAt`.

## Stores (DodoCore public API)

Stores take a `ModelContainer` (or `ModelContext`) at init. They throw `DodoStoreError` for validation failures. They never present UI.

### `DodoStoreError`

- `emptyTitle` — task title or template/category/tag name empty after trim
- `duplicateName` — tag or category name already exists (case-insensitive)
- `invalidURL` — link URL missing, not absolute, or scheme not `http`/`https`/`file`
- `missing` — referenced entity not in the store

### `NoteStore`

- `createNote(title:bodyMarkdown:)` → `Note`
- `updateNote(_:title:bodyMarkdown:)` — omit a field to leave it unchanged
- `deleteNote(_:)` — deletes the note and its `NoteLink`s; linked tasks are unlinked (`note = nil`), not deleted
- `setCategory(_:on:)` — pass `nil` to clear
- `addTag(named:to:)` — finds or creates the tag by case-insensitive name
- `removeTag(_:from:)`
- `addLink(url:label:to:)`
- `removeLink(_:)`
- `apply(template:to:)` — template-insert rule above
- `notes(matching: NoteQuery)` — `all`, `tag(Tag)`, `category(Category)`

### `TaskStore`

- `createTask(title:detail:bucket:status:priority:dueOn:)` → `TaskItem` (defaults: empty detail, `inbox`, `todo`, `none`, no due date)
- `updateTask(_:title:detail:priority:dueOn:)`
- `setStatus(_:on:)`
- `move(_:to:)` — bucket change
- `setCategory(_:on:)`
- `attach(_:to:)` — set `task.note`; attaching to a different note replaces the previous link
- `detach(_:)` — `note = nil`
- `deleteTask(_:)`
- `tasks(in: TaskBucket)` — all tasks in that bucket, newest `updatedAt` first
- `tasks(linkedTo: Note)`

### `SearchIndex`

`search(_ query: String) -> SearchResults`

- Trim query. Empty query returns empty results (not “everything”).
- Case-insensitive substring match.
- Fields: note title, note body, tag names on a note, category name on a note, `NoteLink.url` and `NoteLink.label`, task title, task detail, task category name.
- A note matches if any of its fields match. A task matches if any of its fields match.
- `SearchResults` contains unique notes and unique tasks, each sorted by `updatedAt` descending.
- Matching a tag or category name includes notes/tasks that use that name, not a separate “tag result” row in v0.

### `AppSettings`

UserDefaults keys (string constants in DodoCore; the app binds them with `@AppStorage`):

| Key | Type | Default |
|---|---|---|
| `dodo.fontFamily` | `String` | `".AppleSystemUIFont"` |
| `dodo.fontSize` | `Double` | `14` |
| `dodo.priority.none` | `String` | `"None"` |
| `dodo.priority.low` | `String` | `"Low"` |
| `dodo.priority.medium` | `String` | `"Medium"` |
| `dodo.priority.high` | `String` | `"High"` |

v0 does not add or remove priority levels. Labels are display-only.

Font family is one of: system (`.AppleSystemUIFont`), `New York`, `Georgia`, `SF Mono`. Font size range 12...22.

## Persistence

`Persistence.container(inMemory: Bool) throws -> ModelContainer`

- Schema: `Note`, `Tag`, `Category`, `NoteLink`, `TaskItem`, `NoteTemplate`.
- Disk path: Application Support / `Dodo` / `Dodo.store`.
- In-memory configuration for tests.
- No CloudKit options in v0.

## UI (Dodo app)

Follow macOS HIG. System materials, SF Symbols, standard spacing. No custom web design system.

### Main window

Three-column `NavigationSplitView`.

**Sidebar** (in this order):

1. Today
2. Next Day
3. This Week
4. This Month
5. Inbox
6. Notes
7. Tags (disclosure of tag names that have at least one note)
8. Categories (disclosure of category names)

Selecting Today / Next Day / This Week / This Month / Inbox shows that bucket’s tasks in the list.

Selecting Notes shows all notes, newest `updatedAt` first.

Selecting a tag or category filters the list to notes with that tag or category.

**List**

- Notes: title (or “Untitled”), relative updated date, tag chips.
- Tasks: title, status, priority label, optional due date.
- Empty states: “No notes yet” with a New Note button; “No tasks in this bucket” with a New Task button.

**Detail**

- Note: title field, markdown editor with Edit / Preview segmented control, inspector for category, tags, URL attachments, timestamps (created / updated, read-only), and linked tasks.
- Task: title, detail, status, bucket, priority, due date, category, linked note picker (or “None”).

Markdown preview uses `AttributedString` with markdown; it is not a live HTML preview.

### Menu bar extra

Icon: `bird` SF Symbol (fallback `square.and.pencil` if needed). Menu:

- Quick Note: title field, optional body, ⌘↩ saves and clears the form.
- Quick Task: title field, bucket picker (default Inbox), ⌘↩ saves and clears.
- Open Dodo — activates the main window.

Failed validation (empty task title) leaves the popover open and shows the error inline.

### Settings

Tabs:

1. **General** — font family picker, font size stepper. Changes apply immediately to the note editor.
2. **Templates** — list of templates; add / rename / edit body / delete.
3. **Categories** — list; add / rename / delete (delete nulls references).
4. **Priorities** — four label fields for none / low / medium / high.
5. **Coming later** — disabled rows labeled “Coming later”: Transcription, Local LLM, iCloud, Claude.

### Keyboard

- ⌘N new note (in the current notes context, or switches to Notes)
- ⌘T new task (in the current bucket, or Inbox if viewing notes)
- ⌘F focuses search
- Standard Find in list (filter as-you-type in the list column when search is focused)

Search is an in-window field in the toolbar. Results replace the list with matching notes and tasks grouped under Notes and Tasks headers. Selecting a result opens it in the detail column.

## Error handling

- Store validation errors surface as inline text in the relevant form; they are not silent.
- Persistence failures at launch show a standard alert and refuse to continue with a corrupt in-memory fallback (v0 does not try to repair a damaged store).
- Empty search query shows the normal sidebar-driven list, not an error.

## Testing

Good tests exercise public store/search APIs against an in-memory container. They do not inspect SwiftData internals or mock `ModelContext`.

`DodoCore` Swift Testing coverage (required):

- Create / update / delete note; timestamps bump on update.
- Tags: find-or-create by case-insensitive name; unique name; reject empty.
- Categories: unique name; delete nulls note and task category.
- URL attachments: accept `http`/`https`/`file`; reject empty and unknown schemes.
- Template insert: replace empty body; append to non-empty body.
- Task create rejects empty title; default bucket is inbox.
- Bucket move: any bucket to any other.
- Status can change to each of the four values.
- Attach task to note; re-attach moves the link; delete note unlinks tasks.
- Search: title, body, tag name, category name, URL, task title/detail; empty query returns nothing.

App: if an XCTest UI smoke test is cheap after the window shell exists, add one launch + create-note test. Not a gate for DodoCore.

## GitHub delivery

Repository: `https://github.com/urmindra/dodo.git`.

Work on feature branches. PR into `main`. CI runs `swift test` for `DodoCore` and `xcodebuild test` for the Dodo scheme when Xcode is available.

Vertical slices (each is one issue and one PR):

1. Repo scaffold: Xcode project, `DodoCore` package, README, issue templates, macOS CI.
2. SwiftData models + stores + tests.
3. Main window shell + sidebar + empty states.
4. Notes CRUD: markdown, tags, category, timestamps, URL attachments.
5. Tasks CRUD: buckets, statuses, attach to a note.
6. Menu-bar quick capture.
7. Search across notes, tasks, tags, categories, URLs.
8. Settings: font, templates, categories, priority labels, coming-later placeholders.

## Later phases (not this spec)

- **v1** folders / Spotlight / richer markdown.
- **v2** CloudKit on these SwiftData models.
- **v3** meetings: `SpeechAnalyzer` / `SpeechTranscriber` (macOS 26+), notes + actions from a transcript, same tags/categories. No meeting types in the v0 schema.
- **v4** local LLM: Ollama then Open Router for daily action extraction.
- **v5** Claude as a local MCP server over `DodoCore`; optional in-app chat is a later product decision.
