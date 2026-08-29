import SwiftUI
import DodoCore

enum DodoNote {
    static let newNote = Notification.Name("dodo.newNote")
    static let newTask = Notification.Name("dodo.newTask")
    static let find = Notification.Name("dodo.find")
    static let openMain = Notification.Name("dodo.openMain")
}

enum SidebarItem: Hashable {
    case today
    case nextDay
    case thisWeek
    case thisMonth
    case inbox
    case notes
    case tag(UUID)
    case category(UUID)

    var bucket: TaskBucket? {
        switch self {
        case .today: return .today
        case .nextDay: return .nextDay
        case .thisWeek: return .thisWeek
        case .thisMonth: return .thisMonth
        case .inbox: return .inbox
        default: return nil
        }
    }

    var title: String {
        switch self {
        case .today: return "Today"
        case .nextDay: return "Next Day"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .inbox: return "Inbox"
        case .notes: return "Notes"
        case .tag: return "Tag"
        case .category: return "Category"
        }
    }

    var systemImage: String {
        switch self {
        case .today: return "sun.max"
        case .nextDay: return "sunrise"
        case .thisWeek: return "calendar"
        case .thisMonth: return "calendar.circle"
        case .inbox: return "tray"
        case .notes: return "note.text"
        case .tag: return "tag"
        case .category: return "folder"
        }
    }
}
