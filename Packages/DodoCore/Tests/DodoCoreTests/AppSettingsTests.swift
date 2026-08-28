import Testing
@testable import DodoCore

@Suite
struct AppSettingsTests {
    @Test func defaultKeysAndPriorityLabelsMatchTheSpec() {
        #expect(AppSettings.fontFamilyKey == "dodo.fontFamily")
        #expect(AppSettings.defaultFontSize == 14)
        #expect(AppSettings.defaultPriorityLabel(for: .none) == "None")
        #expect(AppSettings.defaultPriorityLabel(for: .high) == "High")
        #expect(AppSettings.priorityKey(for: .low) == "dodo.priority.low")
        #expect(AppSettings.fontFamilies.contains("SF Mono"))
    }
}
