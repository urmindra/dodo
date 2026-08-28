import Foundation
import Observation

@Observable
public final class Tag: Identifiable {
    public var id: UUID
    public var name: String
    public var notes: [Note]

    public init(name: String) {
        self.id = UUID()
        self.name = name
        self.notes = []
    }
}

@Observable
public final class Category: Identifiable {
    public var id: UUID
    public var name: String
    public var notes: [Note]
    public var tasks: [TaskItem]

    public init(name: String) {
        self.id = UUID()
        self.name = name
        self.notes = []
        self.tasks = []
    }
}

@Observable
public final class NoteLink: Identifiable {
    public var id: UUID
    public var url: String
    public var label: String?
    public var note: Note?

    public init(url: String, label: String? = nil) {
        self.id = UUID()
        self.url = url
        self.label = label
    }
}

@Observable
public final class Note: Identifiable {
    public var id: UUID
    public var title: String
    public var bodyMarkdown: String
    public var createdAt: Date
    public var updatedAt: Date
    public var category: Category?
    public var tags: [Tag]
    public var links: [NoteLink]
    public var tasks: [TaskItem]

    public init(title: String, bodyMarkdown: String = "") {
        self.id = UUID()
        self.title = title
        self.bodyMarkdown = bodyMarkdown
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.tags = []
        self.links = []
        self.tasks = []
    }

    public var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "Untitled"
        }
        return trimmed
    }
}

@Observable
public final class TaskItem: Identifiable {
    public var id: UUID
    public var title: String
    public var detail: String
    public var status: TaskStatus
    public var bucket: TaskBucket
    public var priority: TaskPriority
    public var createdAt: Date
    public var updatedAt: Date
    public var dueOn: Date?
    public var note: Note?
    public var category: Category?

    public init(
        title: String,
        detail: String = "",
        status: TaskStatus = .todo,
        bucket: TaskBucket = .inbox,
        priority: TaskPriority = .none,
        dueOn: Date? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.detail = detail
        self.status = status
        self.bucket = bucket
        self.priority = priority
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.dueOn = dueOn
    }
}

@Observable
public final class NoteTemplate: Identifiable {
    public var id: UUID
    public var name: String
    public var bodyMarkdown: String

    public init(name: String, bodyMarkdown: String) {
        self.id = UUID()
        self.name = name
        self.bodyMarkdown = bodyMarkdown
    }
}
