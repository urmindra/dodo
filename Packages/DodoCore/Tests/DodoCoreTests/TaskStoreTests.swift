import Foundation
import Testing
@testable import DodoCore

@Suite
@MainActor
struct TaskStoreTests {
    @Test func createTaskRejectsEmptyTitleAndDefaultsToInboxTodo() throws {
        let harness = try StoreHarness()
        #expect(throws: DodoStoreError.emptyTitle) {
            try harness.tasks.createTask(title: "  ")
        }
        let task = try harness.tasks.createTask(title: " Ship ")
        #expect(task.title == "Ship")
        #expect(task.bucket == .inbox)
        #expect(task.status == .todo)
        #expect(task.priority == .none)
        #expect(task.detail.isEmpty)
        #expect(task.dueOn == nil)
    }

    @Test func movingATaskToAnyBucketSucceeds() throws {
        let harness = try StoreHarness()
        let task = try harness.tasks.createTask(title: "Move me")
        for bucket in TaskBucket.allCases {
            try harness.tasks.move(task, to: bucket)
            #expect(task.bucket == bucket)
            #expect(harness.tasks.tasks(in: bucket).contains { $0.id == task.id })
        }
    }

    @Test func statusCanChangeToEachValue() throws {
        let harness = try StoreHarness()
        let task = try harness.tasks.createTask(title: "Status")
        for status in TaskStatus.allCases {
            try harness.tasks.setStatus(status, on: task)
            #expect(task.status == status)
        }
    }

    @Test func attachTaskToNoteAndReattachMovesTheLink() throws {
        let harness = try StoreHarness()
        let first = try harness.notes.createNote(title: "First")
        let second = try harness.notes.createNote(title: "Second")
        let task = try harness.tasks.createTask(title: "Follow up")
        try harness.tasks.attach(task, to: first)
        #expect(task.note?.id == first.id)
        #expect(harness.tasks.tasks(linkedTo: first).map(\.id) == [task.id])
        try harness.tasks.attach(task, to: second)
        #expect(task.note?.id == second.id)
        #expect(harness.tasks.tasks(linkedTo: first).isEmpty)
        #expect(harness.tasks.tasks(linkedTo: second).map(\.id) == [task.id])
    }

    @Test func deletingANoteUnlinksTasksInsteadOfDeletingThem() throws {
        let harness = try StoreHarness()
        let note = try harness.notes.createNote(title: "Source")
        let task = try harness.tasks.createTask(title: "Keep me")
        try harness.tasks.attach(task, to: note)
        try harness.notes.deleteNote(note)
        let remaining = harness.tasks.allTasks()
        #expect(remaining.count == 1)
        #expect(remaining[0].id == task.id)
        #expect(remaining[0].note == nil)
    }
}
