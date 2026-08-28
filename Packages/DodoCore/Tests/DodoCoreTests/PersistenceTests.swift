import SwiftData
import Testing
@testable import DodoCore

@Test func inMemoryContainerCanBeCreated() throws {
    let container = try Persistence.container(inMemory: true)
    #expect(container.configurations.first?.isStoredInMemoryOnly == true)
}
