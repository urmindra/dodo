import Foundation
import Observation

@Observable
@MainActor
public final class NoteStore {
    private let context: DodoContext

    public init(context: DodoContext) {
        self.context = context
    }

    @discardableResult
    public func createNote(title: String, bodyMarkdown: String = "") throws -> Note {
        let note = Note(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            bodyMarkdown: bodyMarkdown
        )
        context.notes.append(note)
        try context.save()
        return note
    }

    public func updateNote(_ note: Note, title: String? = nil, bodyMarkdown: String? = nil) throws {
        if let title {
            note.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let bodyMarkdown {
            note.bodyMarkdown = bodyMarkdown
        }
        note.updatedAt = Date()
        try context.save()
    }

    public func deleteNote(_ note: Note) throws {
        for task in note.tasks {
            task.note = nil
        }
        for tag in note.tags {
            tag.notes.removeAll { $0.id == note.id }
        }
        if let category = note.category {
            category.notes.removeAll { $0.id == note.id }
        }
        context.notes.removeAll { $0.id == note.id }
        try context.save()
    }

    public func setCategory(_ category: Category?, on note: Note) throws {
        if let previous = note.category {
            previous.notes.removeAll { $0.id == note.id }
        }
        note.category = category
        if let category, category.notes.contains(where: { $0.id == note.id }) == false {
            category.notes.append(note)
        }
        note.updatedAt = Date()
        try context.save()
    }

    @discardableResult
    public func addTag(named rawName: String, to note: Note) throws -> Tag {
        let name = try TrimmedText.name(rawName)
        let tag = try findOrCreateTag(named: name)
        if note.tags.contains(where: { $0.id == tag.id }) == false {
            note.tags.append(tag)
            tag.notes.append(note)
            note.updatedAt = Date()
            try context.save()
        }
        return tag
    }

    public func removeTag(_ tag: Tag, from note: Note) throws {
        note.tags.removeAll { $0.id == tag.id }
        tag.notes.removeAll { $0.id == note.id }
        note.updatedAt = Date()
        try context.save()
    }

    @discardableResult
    public func addLink(url rawURL: String, label: String? = nil, to note: Note) throws -> NoteLink {
        let url = try LinkURL.parse(rawURL)
        let link = NoteLink(url: url, label: TrimmedText.optionalLabel(label))
        link.note = note
        note.links.append(link)
        note.updatedAt = Date()
        try context.save()
        return link
    }

    public func removeLink(_ link: NoteLink) throws {
        if let note = link.note {
            note.links.removeAll { $0.id == link.id }
            note.updatedAt = Date()
        }
        link.note = nil
        try context.save()
    }

    public func apply(template: NoteTemplate, to note: Note) throws {
        let existing = note.bodyMarkdown.trimmingCharacters(in: .whitespacesAndNewlines)
        if existing.isEmpty {
            note.bodyMarkdown = template.bodyMarkdown
        } else {
            note.bodyMarkdown += "\n\n" + template.bodyMarkdown
        }
        note.updatedAt = Date()
        try context.save()
    }

    public func createTemplate(name: String, bodyMarkdown: String) throws -> NoteTemplate {
        let template = NoteTemplate(name: try TrimmedText.name(name), bodyMarkdown: bodyMarkdown)
        context.templates.append(template)
        try context.save()
        return template
    }

    public func updateTemplate(_ template: NoteTemplate, name: String? = nil, bodyMarkdown: String? = nil) throws {
        if let name {
            template.name = try TrimmedText.name(name)
        }
        if let bodyMarkdown {
            template.bodyMarkdown = bodyMarkdown
        }
        try context.save()
    }

    public func deleteTemplate(_ template: NoteTemplate) throws {
        context.templates.removeAll { $0.id == template.id }
        try context.save()
    }

    public func templates() -> [NoteTemplate] {
        context.templates.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    public func createCategory(name: String) throws -> Category {
        let trimmed = try TrimmedText.name(name)
        if categoryNamed(trimmed) != nil {
            throw DodoStoreError.duplicateName
        }
        let category = Category(name: trimmed)
        context.categories.append(category)
        try context.save()
        return category
    }

    public func renameCategory(_ category: Category, to rawName: String) throws {
        let trimmed = try TrimmedText.name(rawName)
        if let existing = categoryNamed(trimmed), existing.id != category.id {
            throw DodoStoreError.duplicateName
        }
        category.name = trimmed
        try context.save()
    }

    public func deleteCategory(_ category: Category) throws {
        for note in category.notes {
            note.category = nil
        }
        for task in category.tasks {
            task.category = nil
        }
        context.categories.removeAll { $0.id == category.id }
        try context.save()
    }

    public func categories() -> [Category] {
        context.categories.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    public func notes(matching query: NoteQuery = .all) -> [Note] {
        let all = context.notes.sorted { $0.updatedAt > $1.updatedAt }
        switch query {
        case .all:
            return all
        case .tag(let id):
            return all.filter { note in note.tags.contains { $0.id == id } }
        case .category(let id):
            return all.filter { $0.category?.id == id }
        }
    }

    public func tags() -> [Tag] {
        context.tags.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func findOrCreateTag(named name: String) throws -> Tag {
        if let existing = tag(named: name) {
            return existing
        }
        let tag = Tag(name: name)
        context.tags.append(tag)
        try context.save()
        return tag
    }

    private func tag(named name: String) -> Tag? {
        context.tags.first { NameMatch.equals($0.name, name) }
    }

    private func categoryNamed(_ name: String) -> Category? {
        context.categories.first { NameMatch.equals($0.name, name) }
    }
}
