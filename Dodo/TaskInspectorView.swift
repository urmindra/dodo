import SwiftUI
import DodoCore

struct TaskInspectorView: View {
    @Environment(DodoStores.self) private var stores
    @Environment(Workspace.self) private var workspace
    let task: TaskItem
    @State private var title = ""
    @State private var detail = ""
    @AppStorage(AppSettings.priorityNoneKey) private var noneLabel = AppSettings.defaultPriorityNone
    @AppStorage(AppSettings.priorityLowKey) private var lowLabel = AppSettings.defaultPriorityLow
    @AppStorage(AppSettings.priorityMediumKey) private var mediumLabel = AppSettings.defaultPriorityMedium
    @AppStorage(AppSettings.priorityHighKey) private var highLabel = AppSettings.defaultPriorityHigh

    var body: some View {
        Form {
            Section("Task") {
                TextField("Title", text: $title)
                    .onChange(of: title) { _, newValue in
                        try? stores.tasks.updateTask(task, title: newValue)
                    }
                TextField("Detail", text: $detail, axis: .vertical)
                    .lineLimit(3...8)
                    .onChange(of: detail) { _, newValue in
                        try? stores.tasks.updateTask(task, detail: newValue)
                    }
            }
            Section("Organization") {
                Picker("Status", selection: statusBinding) {
                    Text("To do").tag(TaskStatus.todo)
                    Text("In progress").tag(TaskStatus.inProgress)
                    Text("Done").tag(TaskStatus.done)
                    Text("Waiting follow-up").tag(TaskStatus.waitingFollowup)
                }
                Picker("Bucket", selection: bucketBinding) {
                    Text("Inbox").tag(TaskBucket.inbox)
                    Text("Today").tag(TaskBucket.today)
                    Text("Next Day").tag(TaskBucket.nextDay)
                    Text("This Week").tag(TaskBucket.thisWeek)
                    Text("This Month").tag(TaskBucket.thisMonth)
                }
                Picker("Priority", selection: priorityBinding) {
                    Text(noneLabel).tag(TaskPriority.none)
                    Text(lowLabel).tag(TaskPriority.low)
                    Text(mediumLabel).tag(TaskPriority.medium)
                    Text(highLabel).tag(TaskPriority.high)
                }
                DatePicker(
                    "Due",
                    selection: dueBinding,
                    displayedComponents: .date
                )
                Toggle("Has due date", isOn: hasDueBinding)
                Picker("Category", selection: categoryBinding) {
                    Text("None").tag(Optional<UUID>.none)
                    ForEach(stores.notes.categories()) { category in
                        Text(category.name).tag(Optional(category.id))
                    }
                }
                Picker("Note", selection: noteBinding) {
                    Text("None").tag(Optional<UUID>.none)
                    ForEach(stores.notes.notes()) { note in
                        Text(note.displayTitle).tag(Optional(note.id))
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear(perform: load)
        .onChange(of: task.id) { _, _ in load() }
    }

    private var statusBinding: Binding<TaskStatus> {
        Binding(
            get: { task.status },
            set: { try? stores.tasks.setStatus($0, on: task) }
        )
    }

    private var bucketBinding: Binding<TaskBucket> {
        Binding(
            get: { task.bucket },
            set: { bucket in
                try? stores.tasks.move(task, to: bucket)
                workspace.sidebar = SidebarItem.from(bucket: bucket)
            }
        )
    }

    private var priorityBinding: Binding<TaskPriority> {
        Binding(
            get: { task.priority },
            set: { try? stores.tasks.updateTask(task, priority: $0) }
        )
    }

    private var hasDueBinding: Binding<Bool> {
        Binding(
            get: { task.dueOn != nil },
            set: { enabled in
                try? stores.tasks.updateTask(task, dueOn: .some(enabled ? Date() : nil))
            }
        )
    }

    private var dueBinding: Binding<Date> {
        Binding(
            get: { task.dueOn ?? Date() },
            set: { try? stores.tasks.updateTask(task, dueOn: $0) }
        )
    }

    private var categoryBinding: Binding<UUID?> {
        Binding(
            get: { task.category?.id },
            set: { id in
                let category = stores.notes.categories().first { $0.id == id }
                try? stores.tasks.setCategory(category, on: task)
            }
        )
    }

    private var noteBinding: Binding<UUID?> {
        Binding(
            get: { task.note?.id },
            set: { id in
                if let id, let note = stores.notes.notes().first(where: { $0.id == id }) {
                    try? stores.tasks.attach(task, to: note)
                } else {
                    try? stores.tasks.detach(task)
                }
            }
        )
    }

    private func load() {
        title = task.title
        detail = task.detail
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
