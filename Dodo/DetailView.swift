import SwiftUI
import DodoCore

struct DetailView: View {
    @Environment(DodoStores.self) private var stores
    @Environment(Workspace.self) private var workspace

    var body: some View {
        if let id = workspace.selectedNoteID, let note = stores.notes.notes().first(where: { $0.id == id }) {
            NoteEditorView(note: note)
        } else if let id = workspace.selectedTaskID, let task = stores.tasks.allTasks().first(where: { $0.id == id }) {
            TaskInspectorView(task: task)
        } else {
            ContentUnavailableView("Select an item", systemImage: "sidebar.left", description: Text("Choose a note or task from the list."))
        }
    }
}
