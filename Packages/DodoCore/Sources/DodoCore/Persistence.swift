import Foundation
import Observation

@Observable
@MainActor
public final class DodoContext {
    public var isStoredInMemoryOnly: Bool
    public var notes: [Note] = []
    public var tags: [Tag] = []
    public var categories: [Category] = []
    public var templates: [NoteTemplate] = []
    public var tasks: [TaskItem] = []

    public init(isStoredInMemoryOnly: Bool) {
        self.isStoredInMemoryOnly = isStoredInMemoryOnly
    }

    public func save() throws {
        if isStoredInMemoryOnly {
            return
        }
        try LibrarySnapshot.persist(self)
    }
}

public enum Persistence {
    @MainActor
    public static func container(inMemory: Bool = false) throws -> DodoContext {
        if inMemory {
            return DodoContext(isStoredInMemoryOnly: true)
        }

        let context = DodoContext(isStoredInMemoryOnly: false)
        try LibrarySnapshot.load(into: context)
        return context
    }
}

enum PersistenceError: Error, Equatable {
    case applicationSupportUnavailable
}

enum LibrarySnapshot {
    static func storeURL() throws -> URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        guard let support else {
            throw PersistenceError.applicationSupportUnavailable
        }

        let folder = support.appendingPathComponent("Dodo", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("Dodo.json")
    }

    @MainActor
    static func persist(_ context: DodoContext) throws {
        let data = try JSONEncoder.dodo.encode(SnapshotFile(context: context))
        try data.write(to: try storeURL(), options: [.atomic])
    }

    @MainActor
    static func load(into context: DodoContext) throws {
        let url = try storeURL()
        guard FileManager.default.fileExists(atPath: url.path) else {
            return
        }
        let data = try Data(contentsOf: url)
        let file = try JSONDecoder.dodo.decode(SnapshotFile.self, from: data)
        file.apply(to: context)
    }
}

private extension JSONEncoder {
    static var dodo: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var dodo: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

private struct SnapshotFile: Codable {
    var notes: [NoteRecord]
    var tags: [NamedRecord]
    var categories: [NamedRecord]
    var templates: [TemplateRecord]
    var tasks: [TaskRecord]
    var links: [LinkRecord]

    @MainActor
    init(context: DodoContext) {
        notes = context.notes.map(NoteRecord.init)
        tags = context.tags.map { NamedRecord(id: $0.id, name: $0.name) }
        categories = context.categories.map { NamedRecord(id: $0.id, name: $0.name) }
        templates = context.templates.map { TemplateRecord(id: $0.id, name: $0.name, bodyMarkdown: $0.bodyMarkdown) }
        tasks = context.tasks.map(TaskRecord.init)
        links = context.notes.flatMap { note in
            note.links.map { LinkRecord(id: $0.id, url: $0.url, label: $0.label, noteID: note.id) }
        }
    }

    @MainActor
    func apply(to context: DodoContext) {
        let tagsByID = Dictionary(uniqueKeysWithValues: tags.map { record in
            (record.id, Tag(name: record.name).withID(record.id))
        })
        let categoriesByID = Dictionary(uniqueKeysWithValues: categories.map { record in
            (record.id, Category(name: record.name).withID(record.id))
        })

        context.tags = Array(tagsByID.values)
        context.categories = Array(categoriesByID.values)
        context.templates = templates.map {
            NoteTemplate(name: $0.name, bodyMarkdown: $0.bodyMarkdown).withID($0.id)
        }

        var notesByID: [UUID: Note] = [:]
        context.notes = notes.map { record in
            let note = Note(title: record.title, bodyMarkdown: record.bodyMarkdown).withID(record.id)
            note.createdAt = record.createdAt
            note.updatedAt = record.updatedAt
            note.category = record.categoryID.flatMap { categoriesByID[$0] }
            note.tags = record.tagIDs.compactMap { tagsByID[$0] }
            notesByID[note.id] = note
            return note
        }

        for tag in context.tags {
            tag.notes = context.notes.filter { note in note.tags.contains { $0.id == tag.id } }
        }
        for category in context.categories {
            category.notes = context.notes.filter { $0.category?.id == category.id }
        }

        context.tasks = tasks.map { record in
            let task = TaskItem(
                title: record.title,
                detail: record.detail,
                status: TaskStatus(rawValue: record.status) ?? .todo,
                bucket: TaskBucket(rawValue: record.bucket) ?? .inbox,
                priority: TaskPriority(rawValue: record.priority) ?? .none,
                dueOn: record.dueOn
            ).withID(record.id)
            task.createdAt = record.createdAt
            task.updatedAt = record.updatedAt
            task.note = record.noteID.flatMap { notesByID[$0] }
            task.category = record.categoryID.flatMap { categoriesByID[$0] }
            return task
        }

        for note in context.notes {
            note.tasks = context.tasks.filter { $0.note?.id == note.id }
            note.links = links.filter { $0.noteID == note.id }.map { record in
                let link = NoteLink(url: record.url, label: record.label)
                link.id = record.id
                link.note = note
                return link
            }
        }
        for category in context.categories {
            category.tasks = context.tasks.filter { $0.category?.id == category.id }
        }
    }
}

private struct NamedRecord: Codable {
    var id: UUID
    var name: String
}

private struct TemplateRecord: Codable {
    var id: UUID
    var name: String
    var bodyMarkdown: String
}

private struct NoteRecord: Codable {
    var id: UUID
    var title: String
    var bodyMarkdown: String
    var createdAt: Date
    var updatedAt: Date
    var categoryID: UUID?
    var tagIDs: [UUID]

    init(note: Note) {
        id = note.id
        title = note.title
        bodyMarkdown = note.bodyMarkdown
        createdAt = note.createdAt
        updatedAt = note.updatedAt
        categoryID = note.category?.id
        tagIDs = note.tags.map(\.id)
    }
}

private struct LinkRecord: Codable {
    var id: UUID
    var url: String
    var label: String?
    var noteID: UUID
}

private struct TaskRecord: Codable {
    var id: UUID
    var title: String
    var detail: String
    var status: String
    var bucket: String
    var priority: String
    var createdAt: Date
    var updatedAt: Date
    var dueOn: Date?
    var noteID: UUID?
    var categoryID: UUID?

    init(task: TaskItem) {
        id = task.id
        title = task.title
        detail = task.detail
        status = task.status.rawValue
        bucket = task.bucket.rawValue
        priority = task.priority.rawValue
        createdAt = task.createdAt
        updatedAt = task.updatedAt
        dueOn = task.dueOn
        noteID = task.note?.id
        categoryID = task.category?.id
    }
}

private extension Tag {
    func withID(_ id: UUID) -> Tag {
        self.id = id
        return self
    }
}

private extension Category {
    func withID(_ id: UUID) -> Category {
        self.id = id
        return self
    }
}

private extension Note {
    func withID(_ id: UUID) -> Note {
        self.id = id
        return self
    }
}

private extension TaskItem {
    func withID(_ id: UUID) -> TaskItem {
        self.id = id
        return self
    }
}

private extension NoteTemplate {
    func withID(_ id: UUID) -> NoteTemplate {
        self.id = id
        return self
    }
}
