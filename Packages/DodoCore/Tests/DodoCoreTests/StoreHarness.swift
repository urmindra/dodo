import Foundation
import Testing
@testable import DodoCore

@MainActor
struct StoreHarness {
    let container: DodoContext
    let stores: DodoStores
    var notes: NoteStore { stores.notes }
    var tasks: TaskStore { stores.tasks }
    var search: SearchIndex { stores.search }

    init() throws {
        container = try Persistence.container(inMemory: true)
        stores = DodoStores(container: container)
    }
}

func expectDate(_ date: Date, closeTo other: Date) {
    #expect(abs(date.timeIntervalSince(other)) < 2)
}
