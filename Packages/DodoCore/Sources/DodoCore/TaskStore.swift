import Foundation
import Observation

@Observable
@MainActor
public final class TaskStore {
    private let context: DodoContext

    public init(context: DodoContext) {
        self.context = context
    }

    @discardableResult
    public func createTask(
        title: String,
        detail: String = "",
        bucket: TaskBucket = .inbox,
        status: TaskStatus = .todo,
        priority: TaskPriority = .none,
        dueOn: Date? = nil
    ) throws -> TaskItem {
        let trimmed = try TrimmedText.name(title)
        let task = TaskItem(
            title: trimmed,
            detail: detail,
            status: status,
            bucket: bucket,
            priority: priority,
            dueOn: dueOn
        )
        context.tasks.append(task)
        try context.save()
        return task
    }

    public func updateTask(
        _ task: TaskItem,
        title: String? = nil,
        detail: String? = nil,
        priority: TaskPriority? = nil,
        dueOn: Date?? = nil
    ) throws {
        if let title {
            task.title = try TrimmedText.name(title)
        }
        if let detail {
            task.detail = detail
        }
        if let priority {
            task.priority = priority
        }
        if let dueOn {
            task.dueOn = dueOn
        }
        task.updatedAt = Date()
        try context.save()
    }

    public func setStatus(_ status: TaskStatus, on task: TaskItem) throws {
        task.status = status
        task.updatedAt = Date()
        try context.save()
    }

    public func move(_ task: TaskItem, to bucket: TaskBucket) throws {
        task.bucket = bucket
        task.updatedAt = Date()
        try context.save()
    }

    public func setCategory(_ category: Category?, on task: TaskItem) throws {
        if let previous = task.category {
            previous.tasks.removeAll { $0.id == task.id }
        }
        task.category = category
        if let category, category.tasks.contains(where: { $0.id == task.id }) == false {
            category.tasks.append(task)
        }
        task.updatedAt = Date()
        try context.save()
    }

    public func attach(_ task: TaskItem, to note: Note) throws {
        if let previous = task.note {
            previous.tasks.removeAll { $0.id == task.id }
        }
        task.note = note
        if note.tasks.contains(where: { $0.id == task.id }) == false {
            note.tasks.append(task)
        }
        task.updatedAt = Date()
        try context.save()
    }

    public func detach(_ task: TaskItem) throws {
        if let note = task.note {
            note.tasks.removeAll { $0.id == task.id }
        }
        task.note = nil
        task.updatedAt = Date()
        try context.save()
    }

    public func deleteTask(_ task: TaskItem) throws {
        if let note = task.note {
            note.tasks.removeAll { $0.id == task.id }
        }
        if let category = task.category {
            category.tasks.removeAll { $0.id == task.id }
        }
        context.tasks.removeAll { $0.id == task.id }
        try context.save()
    }

    public func tasks(in bucket: TaskBucket) -> [TaskItem] {
        context.tasks.filter { $0.bucket == bucket }.sorted { $0.updatedAt > $1.updatedAt }
    }

    public func tasks(linkedTo note: Note) -> [TaskItem] {
        note.tasks.sorted { $0.updatedAt > $1.updatedAt }
    }

    public func allTasks() -> [TaskItem] {
        context.tasks.sorted { $0.updatedAt > $1.updatedAt }
    }
}
