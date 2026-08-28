import Foundation
import SwiftData

public enum Persistence {
    public static func container(inMemory: Bool = false) throws -> ModelContainer {
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        } else {
            configuration = ModelConfiguration(url: try storeURL())
        }

        return try ModelContainer(for: Schema([]), configurations: configuration)
    }

    private static func storeURL() throws -> URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        guard let support else {
            throw PersistenceError.applicationSupportUnavailable
        }

        let folder = support.appendingPathComponent("Dodo", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("Dodo.store")
    }
}

public enum PersistenceError: Error, Equatable {
    case applicationSupportUnavailable
}
