import Foundation
import Observation

public struct SearchResults {
    public var notes: [Note]
    public var tasks: [TaskItem]

    public init(notes: [Note] = [], tasks: [TaskItem] = []) {
        self.notes = notes
        self.tasks = tasks
    }

    public var isEmpty: Bool {
        notes.isEmpty && tasks.isEmpty
    }
}

@Observable
@MainActor
public final class SearchIndex {
    private let context: DodoContext

    public init(context: DodoContext) {
        self.context = context
    }

    public func search(_ query: String) -> SearchResults {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if needle.isEmpty {
            return SearchResults()
        }

        let matchedNotes = context.notes
            .filter { noteMatches($0, needle: needle) }
            .sorted { $0.updatedAt > $1.updatedAt }
        let matchedTasks = context.tasks
            .filter { taskMatches($0, needle: needle) }
            .sorted { $0.updatedAt > $1.updatedAt }
        return SearchResults(notes: matchedNotes, tasks: matchedTasks)
    }

    private func noteMatches(_ note: Note, needle: String) -> Bool {
        if contains(note.title, needle) || contains(note.bodyMarkdown, needle) {
            return true
        }
        if note.tags.contains(where: { contains($0.name, needle) }) {
            return true
        }
        if let category = note.category, contains(category.name, needle) {
            return true
        }
        return note.links.contains { link in
            contains(link.url, needle) || contains(link.label ?? "", needle)
        }
    }

    private func taskMatches(_ task: TaskItem, needle: String) -> Bool {
        if contains(task.title, needle) || contains(task.detail, needle) {
            return true
        }
        if let category = task.category, contains(category.name, needle) {
            return true
        }
        return false
    }

    private func contains(_ haystack: String, _ needle: String) -> Bool {
        haystack.range(of: needle, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }
}
