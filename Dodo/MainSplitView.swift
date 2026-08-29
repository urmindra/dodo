import SwiftUI
import DodoCore

struct MainSplitView: View {
    @Environment(DodoStores.self) private var stores
    @Environment(Workspace.self) private var workspace
    @FocusState private var searchFocused: Bool

    var body: some View {
        @Bindable var workspace = workspace
        NavigationSplitView {
            SidebarView()
        } content: {
            ItemListView()
        } detail: {
            DetailView()
        }
        .navigationSplitViewStyle(.balanced)
        .searchable(text: $workspace.searchText, prompt: "Search notes and tasks")
        .searchFocused($searchFocused)
        .onChange(of: workspace.focusSearch) { _, shouldFocus in
            if shouldFocus {
                searchFocused = true
                workspace.focusSearch = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: DodoNote.newNote)) { _ in
            createNote()
        }
        .onReceive(NotificationCenter.default.publisher(for: DodoNote.newTask)) { _ in
            createTask()
        }
        .onReceive(NotificationCenter.default.publisher(for: DodoNote.find)) { _ in
            workspace.focusSearch = true
        }
        .onReceive(NotificationCenter.default.publisher(for: DodoNote.openMain)) { _ in
            workspace.openMainWindow()
        }
    }

    private func createNote() {
        do {
            let note = try stores.notes.createNote(title: "")
            workspace.sidebar = .notes
            workspace.searchText = ""
            workspace.selectedNoteID = note.id
            workspace.selectedTaskID = nil
        } catch {
            return
        }
    }

    private func createTask() {
        let bucket = workspace.sidebar.bucket ?? .inbox
        do {
            let task = try stores.tasks.createTask(title: "New Task", bucket: bucket)
            workspace.sidebar = SidebarItem.from(bucket: bucket)
            workspace.searchText = ""
            workspace.selectedTaskID = task.id
            workspace.selectedNoteID = nil
        } catch {
            return
        }
    }
}

private extension SidebarItem {
    static func from(bucket: TaskBucket) -> SidebarItem {
        switch bucket {
        case .today: return .today
        case .nextDay: return .nextDay
        case .thisWeek: return .thisWeek
        case .thisMonth: return .thisMonth
        case .inbox: return .inbox
        }
    }
}
