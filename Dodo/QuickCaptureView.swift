import SwiftUI
import DodoCore

struct QuickCaptureView: View {
    @Environment(DodoStores.self) private var stores
    @Environment(Workspace.self) private var workspace
    @State private var noteTitle = ""
    @State private var noteBody = ""
    @State private var taskTitle = ""
    @State private var taskBucket: TaskBucket = .inbox
    @State private var taskError: String?
    @FocusState private var focus: CaptureFocus?

    private enum CaptureFocus {
        case note
        case task
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Dodo")
                .font(.headline)

            GroupBox("Quick Note") {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Title", text: $noteTitle)
                        .focused($focus, equals: .note)
                        .onSubmit(saveNote)
                    TextField("Body", text: $noteBody, axis: .vertical)
                        .lineLimit(2...4)
                        .focused($focus, equals: .note)
                        .onSubmit(saveNote)
                    Button("Save Note") {
                        saveNote()
                    }
                }
                .padding(4)
            }

            GroupBox("Quick Task") {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Title", text: $taskTitle)
                        .focused($focus, equals: .task)
                        .onSubmit(saveTask)
                    Picker("Bucket", selection: $taskBucket) {
                        Text("Inbox").tag(TaskBucket.inbox)
                        Text("Today").tag(TaskBucket.today)
                        Text("Next Day").tag(TaskBucket.nextDay)
                        Text("This Week").tag(TaskBucket.thisWeek)
                        Text("This Month").tag(TaskBucket.thisMonth)
                    }
                    if let taskError {
                        Text(taskError).foregroundStyle(.red).font(.caption)
                    }
                    Button("Save Task") {
                        saveTask()
                    }
                }
                .padding(4)
            }

            Button("Save") {
                saveFocused()
            }
            .keyboardShortcut(.return, modifiers: .command)
            .frame(width: 0, height: 0)
            .opacity(0)
            .accessibilityHidden(true)

            Button("Open Dodo") {
                workspace.openMainWindow()
            }
        }
        .padding()
        .frame(width: 320)
    }

    private func saveFocused() {
        if focus == .task {
            saveTask()
            return
        }
        saveNote()
    }

    private func saveNote() {
        _ = try? stores.notes.createNote(title: noteTitle, bodyMarkdown: noteBody)
        noteTitle = ""
        noteBody = ""
    }

    private func saveTask() {
        do {
            _ = try stores.tasks.createTask(title: taskTitle, bucket: taskBucket)
            taskTitle = ""
            taskError = nil
        } catch {
            taskError = "A task needs a title."
        }
    }
}
