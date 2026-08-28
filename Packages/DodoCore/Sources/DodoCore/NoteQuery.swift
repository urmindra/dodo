import Foundation

public enum NoteQuery: Equatable {
    case all
    case tag(UUID)
    case category(UUID)
}
