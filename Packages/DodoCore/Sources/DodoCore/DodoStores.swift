import Observation

@Observable
@MainActor
public final class DodoStores {
    public let context: DodoContext
    public let notes: NoteStore
    public let tasks: TaskStore
    public let search: SearchIndex

    public init(container: DodoContext) {
        self.context = container
        self.notes = NoteStore(context: container)
        self.tasks = TaskStore(context: container)
        self.search = SearchIndex(context: container)
    }
}
