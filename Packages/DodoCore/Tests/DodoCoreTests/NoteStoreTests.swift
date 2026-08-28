import Foundation
import Testing
@testable import DodoCore

@Suite
@MainActor
struct NoteStoreTests {
    @Test func createNoteSetsTitleBodyAndTimestamps() throws {
        let harness = try StoreHarness()
        let before = Date()
        let note = try harness.notes.createNote(title: " Hello ", bodyMarkdown: "# Hi")
        #expect(note.title == "Hello")
        #expect(note.bodyMarkdown == "# Hi")
        #expect(note.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
        expectDate(note.createdAt, closeTo: before)
        #expect(note.updatedAt == note.createdAt)
        #expect(note.displayTitle == "Hello")
    }

    @Test func emptyTitleDisplaysAsUntitled() throws {
        let harness = try StoreHarness()
        let note = try harness.notes.createNote(title: "   ")
        #expect(note.title.isEmpty)
        #expect(note.displayTitle == "Untitled")
    }

    @Test func updateNoteBumpsUpdatedAt() throws {
        let harness = try StoreHarness()
        let note = try harness.notes.createNote(title: "A", bodyMarkdown: "one")
        let created = note.createdAt
        try harness.notes.updateNote(note, title: "B", bodyMarkdown: "two")
        #expect(note.title == "B")
        #expect(note.bodyMarkdown == "two")
        #expect(note.updatedAt >= created)
        #expect(note.createdAt == created)
    }

    @Test func deleteNoteRemovesItFromAllNotes() throws {
        let harness = try StoreHarness()
        let note = try harness.notes.createNote(title: "Gone")
        try harness.notes.deleteNote(note)
        #expect(harness.notes.notes().isEmpty)
    }

    @Test func addTagFindsOrCreatesByCaseInsensitiveName() throws {
        let harness = try StoreHarness()
        let first = try harness.notes.createNote(title: "One")
        let second = try harness.notes.createNote(title: "Two")
        let tag = try harness.notes.addTag(named: " Work ", to: first)
        let reused = try harness.notes.addTag(named: "work", to: second)
        #expect(tag.id == reused.id)
        #expect(tag.name == "Work")
        #expect(harness.notes.tags().count == 1)
    }

    @Test func emptyTagNameIsRejected() throws {
        let harness = try StoreHarness()
        let note = try harness.notes.createNote(title: "N")
        #expect(throws: DodoStoreError.emptyTitle) {
            try harness.notes.addTag(named: "  ", to: note)
        }
    }

    @Test func categoriesAreUniqueCaseInsensitivelyAndDeleteNullsReferences() throws {
        let harness = try StoreHarness()
        let work = try harness.notes.createCategory(name: "Work")
        #expect(throws: DodoStoreError.duplicateName) {
            try harness.notes.createCategory(name: "work")
        }
        let note = try harness.notes.createNote(title: "N")
        try harness.notes.setCategory(work, on: note)
        let task = try harness.tasks.createTask(title: "T")
        try harness.tasks.setCategory(work, on: task)
        try harness.notes.deleteCategory(work)
        #expect(note.category == nil)
        #expect(task.category == nil)
    }

    @Test func urlAttachmentsValidateSchemes() throws {
        let harness = try StoreHarness()
        let note = try harness.notes.createNote(title: "Links")
        let https = try harness.notes.addLink(url: "https://example.com/a", label: " Example ", to: note)
        #expect(https.label == "Example")
        _ = try harness.notes.addLink(url: "http://example.com", to: note)
        _ = try harness.notes.addLink(url: "file:///tmp/note.md", to: note)
        #expect(throws: DodoStoreError.invalidURL) {
            try harness.notes.addLink(url: "ftp://example.com", to: note)
        }
        #expect(throws: DodoStoreError.invalidURL) {
            try harness.notes.addLink(url: "", to: note)
        }
        #expect(note.links.count == 3)
    }

    @Test func templateInsertReplacesEmptyAndAppendsToNonEmpty() throws {
        let harness = try StoreHarness()
        let template = try harness.notes.createTemplate(name: "Daily", bodyMarkdown: "## Done")
        let empty = try harness.notes.createNote(title: "E")
        try harness.notes.apply(template: template, to: empty)
        #expect(empty.bodyMarkdown == "## Done")
        let filled = try harness.notes.createNote(title: "F", bodyMarkdown: "Hello")
        try harness.notes.apply(template: template, to: filled)
        #expect(filled.bodyMarkdown == "Hello\n\n## Done")
    }

    @Test func emptyTemplateNameIsRejected() throws {
        let harness = try StoreHarness()
        #expect(throws: DodoStoreError.emptyTitle) {
            try harness.notes.createTemplate(name: " ", bodyMarkdown: "x")
        }
    }
}
