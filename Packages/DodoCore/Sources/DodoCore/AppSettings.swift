import Foundation

public enum AppSettings {
    public static let fontFamilyKey = "dodo.fontFamily"
    public static let fontSizeKey = "dodo.fontSize"
    public static let priorityNoneKey = "dodo.priority.none"
    public static let priorityLowKey = "dodo.priority.low"
    public static let priorityMediumKey = "dodo.priority.medium"
    public static let priorityHighKey = "dodo.priority.high"

    public static let defaultFontFamily = ".AppleSystemUIFont"
    public static let defaultFontSize: Double = 14
    public static let minimumFontSize: Double = 12
    public static let maximumFontSize: Double = 22

    public static let defaultPriorityNone = "None"
    public static let defaultPriorityLow = "Low"
    public static let defaultPriorityMedium = "Medium"
    public static let defaultPriorityHigh = "High"

    public static let fontFamilies = [
        ".AppleSystemUIFont",
        "New York",
        "Georgia",
        "SF Mono"
    ]

    public static func priorityKey(for priority: TaskPriority) -> String {
        switch priority {
        case .none: return priorityNoneKey
        case .low: return priorityLowKey
        case .medium: return priorityMediumKey
        case .high: return priorityHighKey
        }
    }

    public static func defaultPriorityLabel(for priority: TaskPriority) -> String {
        switch priority {
        case .none: return defaultPriorityNone
        case .low: return defaultPriorityLow
        case .medium: return defaultPriorityMedium
        case .high: return defaultPriorityHigh
        }
    }
}
