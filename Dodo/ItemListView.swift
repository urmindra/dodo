import SwiftUI
import DodoCore

struct ItemListView: View {
    @Environment(DodoStores.self) private var stores
    @Environment(Workspace.self) private var workspace

    var body: some View {
        @Bindable var workspace = workspace
        Group {
            if workspace.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                searchList
            } else if let bucket = workspace.sidebar.bucket {
                taskList(bucket: bucket)
            } else {
                noteList()
            }
        }
        .navigationSplitViewColumnWidth(min: 220, ideal: 280)
    }

    @ViewBuilder
    private var searchList: some View {
        let results = stores.search.search(workspace.searchText)
        List {
            if results.notes.isEmpty == false {
                Section("Notes") {
                    ForEach(results.notes) { note in
                        Button {
                            workspace.show(note: note)
                        } label: {
                            NoteRow(note: note)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            if results.tasks.isEmpty == false {
                Section("Tasks") {
                    ForEach(results.tasks) { task in
                        Button {
                            workspace.show(task: task)
                        } label: {
                            TaskRow(task: task)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            if results.isEmpty {
                ContentUnavailableView.search(text: workspace.searchText)
            }
        }
        .navigationTitle("Search")
    }

    @ViewBuilder
    private func noteList() -> some View {
        @Bindable var workspace = workspace
        let notes = notesForSidebar()
        List(selection: $workspace.selectedNoteID) {
            ForEach(notes) { note in
                NoteRow(note: note)
                    .tag(Optional(note.id))
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            delete(note: note)
                        }
                    }
            }
        }
        .navigationTitle(noteListTitle)
        .overlay {
            if notes.isEmpty {
                EmptyStateView(
                    systemImage: "note.text",
                    title: "No notes yet",
                    subtitle: "Capture a markdown note.",
                    actionTitle: "New Note"
                ) {
                    NotificationCenter.default.post(name: DodoNote.newNote, object: nil)
                }
            }
        }
        .onChange(of: workspace.selectedNoteID) { _, _ in
            workspace.selectedTaskID = nil
        }
    }

    @ViewBuilder
    private func taskList(bucket: TaskBucket) -> some View {
        @Bindable var workspace = workspace
        let tasks = stores.tasks.tasks(in: bucket)
        List(selection: $workspace.selectedTaskID) {
            ForEach(tasks) { task in
                TaskRow(task: task)
                    .tag(Optional(task.id))
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            delete(task: task)
                        }
                    }
            }
        }
        .navigationTitle(workspace.sidebar.title)
        .overlay {
            if tasks.isEmpty {
                EmptyStateView(
                    systemImage: "checkmark.circle",
                    title: "No tasks in this bucket",
                    subtitle: "Park a task here.",
                    actionTitle: "New Task"
                ) {
                    NotificationCenter.default.post(name: DodoNote.newTask, object: nil)
                }
            }
        }
        .onChange(of: workspace.selectedTaskID) { _, _ in
            workspace.selectedNoteID = nil
        }
    }

    private var noteListTitle: String {
        switch workspace.sidebar {
        case .tag(let id):
            return stores.notes.tags().first { $0.id == id }?.name ?? "Tag"
        case .category(let id):
            return stores.notes.categories().first { $0.id == id }?.name ?? "Category"
        default:
            return "Notes"
        }
    }

    private func notesForSidebar() -> [Note] {
        switch workspace.sidebar {
        case .tag(let id):
            return stores.notes.notes(matching: .tag(id))
        case .category(let id):
            return stores.notes.notes(matching: .category(id))
        default:
            return stores.notes.notes()
        }
    }

    private func delete(note: Note) {
        if workspace.selectedNoteID == note.id {
            workspace.selectedNoteID = nil
        }
        try? stores.notes.deleteNote(note)
    }

    private func delete(task: TaskItem) {
        if workspace.selectedTaskID == task.id {
            workspace.selectedTaskID = nil
        }
        try? stores.tasks.deleteTask(task)
    }
}

struct NoteRow: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.displayTitle)
                .font(.headline)
            Text(note.updatedAt, style: .relative)
                .font(.caption)
                .foregroundStyle(.secondary)
            if note.tags.isEmpty == false {
                Text(note.tags.map(\.name).joined(separator: " · "))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct TaskRow: View {
    let task: TaskItem
    @AppStorage(AppSettings.priorityNoneKey) private var noneLabel = AppSettings.defaultPriorityNone
    @AppStorage(AppSettings.priorityLowKey) private var lowLabel = AppSettings.defaultPriorityLow
    @AppStorage(AppSettings.priorityMediumKey) private var mediumLabel = AppSettings.defaultPriorityMedium
    @AppStorage(AppSettings.priorityHighKey) private var highLabel = AppSettings.defaultPriorityHigh

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(task.title)
                .font(.headline)
            HStack {
                Text(statusLabel)
                Text("·")
                Text(priorityLabel)
                if let dueOn = task.dueOn {
                    Text("·")
                    Text(dueOn, style: .date)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var statusLabel: String {
        switch task.status {
        case .todo: return "To do"
        case .inProgress: return "In progress"
        case .done: return "Done"
        case .waitingFollowup: return "Waiting follow-up"
        }
    }

    private var priorityLabel: String {
        switch task.priority {
        case .none: return noneLabel
        case .low: return lowLabel
        case .medium: return mediumLabel
        case .high: return highLabel
        }
    }
}
