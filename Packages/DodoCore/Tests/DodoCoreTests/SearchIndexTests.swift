import Foundation
import Testing
@testable import DodoCore

@Suite
@MainActor
struct SearchIndexTests {
    @Test func emptyQueryReturnsNoHits() throws {
        let harness = try StoreHarness()
        _ = try harness.notes.createNote(title: "Alpha")
        let results = harness.search.search("   ")
        #expect(results.isEmpty)
    }

    @Test func searchMatchesTitleBodyTagCategoryURLAndTaskFields() throws {
        let harness = try StoreHarness()
        let category = try harness.notes.createCategory(name: "Research")
        let note = try harness.notes.createNote(title: "Zettel", bodyMarkdown: "Contains foobar insight")
        try harness.notes.setCategory(category, on: note)
        _ = try harness.notes.addTag(named: "lattice", to: note)
        _ = try harness.notes.addLink(url: "https://example.com/unique-path", label: "Source", to: note)
        let task = try harness.tasks.createTask(title: "Write summary", detail: "Include foobar quote")
        try harness.tasks.setCategory(category, on: task)

        #expect(harness.search.search("zettel").notes.map(\.id) == [note.id])
        #expect(harness.search.search("FOOBAR").notes.map(\.id) == [note.id])
        #expect(harness.search.search("lattice").notes.map(\.id) == [note.id])
        #expect(harness.search.search("research").notes.map(\.id) == [note.id])
        #expect(harness.search.search("unique-path").notes.map(\.id) == [note.id])
        #expect(harness.search.search("write summary").tasks.map(\.id) == [task.id])
        #expect(harness.search.search("foobar").tasks.map(\.id) == [task.id])
        #expect(harness.search.search("research").tasks.map(\.id) == [task.id])
    }
}
