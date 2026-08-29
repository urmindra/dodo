import Foundation
import Observation
import DodoCore
import AppKit

@Observable
@MainActor
final class Workspace {
    var sidebar: SidebarItem = .notes
    var selectedNoteID: UUID?
    var selectedTaskID: UUID?
    var searchText = ""
    var focusSearch = false

    func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows {
            guard window.canBecomeMain, window.level == .normal else { continue }
            window.makeKeyAndOrderFront(nil)
            return
        }
    }

    func show(note: Note) {
        sidebar = .notes
        selectedNoteID = note.id
        selectedTaskID = nil
        searchText = ""
        openMainWindow()
    }

    func show(task: TaskItem) {
        sidebar = SidebarItem.from(bucket: task.bucket)
        selectedTaskID = task.id
        selectedNoteID = nil
        searchText = ""
        openMainWindow()
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
