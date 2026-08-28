import Foundation

public enum TaskStatus: String, Codable, CaseIterable, Sendable {
    case todo
    case inProgress
    case done
    case waitingFollowup
}

public enum TaskBucket: String, Codable, CaseIterable, Sendable {
    case inbox
    case today
    case nextDay
    case thisWeek
    case thisMonth
}

public enum TaskPriority: String, Codable, CaseIterable, Sendable {
    case none
    case low
    case medium
    case high
}
