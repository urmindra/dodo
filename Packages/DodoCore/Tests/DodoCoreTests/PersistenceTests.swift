import Foundation
import Testing
@testable import DodoCore

@Test
@MainActor
func inMemoryContainerCanBeCreated() throws {
        let container = try Persistence.container(inMemory: true)
        #expect(container.isStoredInMemoryOnly == true)
}
