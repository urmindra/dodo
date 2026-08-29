import SwiftUI
import AppKit
import DodoCore

@main
struct DodoApp: App {
    @State private var stores: DodoStores
    @State private var workspace = Workspace()
    @State private var launchError: String?

    init() {
        do {
            let context = try Persistence.container(inMemory: false)
            _stores = State(initialValue: DodoStores(container: context))
        } catch {
            _stores = State(initialValue: DodoStores(container: DodoContext(isStoredInMemoryOnly: true)))
            _launchError = State(initialValue: error.localizedDescription)
        }
    }

    var body: some Scene {
        WindowGroup {
            MainSplitView()
                .environment(stores)
                .environment(workspace)
                .alert(
                    "Couldn’t open the Dodo library",
                    isPresented: Binding(
                        get: { launchError != nil },
                        set: { if $0 == false { NSApp.terminate(nil) } }
                    )
                ) {
                    Button("Quit", role: .destructive) { NSApp.terminate(nil) }
                } message: {
                    Text(launchError ?? "")
                }
        }
        .defaultSize(width: 1100, height: 720)
        .commands {
            DodoCommands()
        }

        Settings {
            SettingsRootView()
                .environment(stores)
        }

        MenuBarExtra("Dodo", systemImage: "bird") {
            QuickCaptureView()
                .environment(stores)
                .environment(workspace)
        }
        .menuBarExtraStyle(.window)
    }
}

struct DodoCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Note") {
                NotificationCenter.default.post(name: DodoNote.newNote, object: nil)
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("New Task") {
                NotificationCenter.default.post(name: DodoNote.newTask, object: nil)
            }
            .keyboardShortcut("t", modifiers: .command)
        }

        CommandGroup(after: .textEditing) {
            Button("Find") {
                NotificationCenter.default.post(name: DodoNote.find, object: nil)
            }
            .keyboardShortcut("f", modifiers: .command)
        }
    }
}
