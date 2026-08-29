import SwiftUI
import DodoCore

struct SidebarView: View {
    @Environment(DodoStores.self) private var stores
    @Environment(Workspace.self) private var workspace

    var body: some View {
        @Bindable var workspace = workspace
        List(selection: $workspace.sidebar) {
            Section("Tasks") {
                ForEach(taskItems, id: \.self) { item in
                    Label(item.title, systemImage: item.systemImage)
                        .tag(item)
                }
            }
            Section("Library") {
                Label("Notes", systemImage: SidebarItem.notes.systemImage)
                    .tag(SidebarItem.notes)

                if stores.notes.tags().isEmpty == false {
                    DisclosureGroup("Tags") {
                        ForEach(stores.notes.tags()) { tag in
                            Label(tag.name, systemImage: "tag")
                                .tag(SidebarItem.tag(tag.id))
                        }
                    }
                }

                if stores.notes.categories().isEmpty == false {
                    DisclosureGroup("Categories") {
                        ForEach(stores.notes.categories()) { category in
                            Label(category.name, systemImage: "folder")
                                .tag(SidebarItem.category(category.id))
                        }
                    }
                }
            }
        }
        .navigationSplitViewColumnWidth(min: 180, ideal: 220)
    }

    private var taskItems: [SidebarItem] {
        [.today, .nextDay, .thisWeek, .thisMonth, .inbox]
    }
}
