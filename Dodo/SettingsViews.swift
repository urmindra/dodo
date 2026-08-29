import SwiftUI
import DodoCore

struct SettingsRootView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "textformat") }
            TemplatesSettingsView()
                .tabItem { Label("Templates", systemImage: "doc.text") }
            CategoriesSettingsView()
                .tabItem { Label("Categories", systemImage: "folder") }
            PrioritySettingsView()
                .tabItem { Label("Priorities", systemImage: "flag") }
            ComingLaterSettingsView()
                .tabItem { Label("Coming later", systemImage: "clock") }
        }
        .frame(minWidth: 480, minHeight: 360)
        .padding()
    }
}

struct GeneralSettingsView: View {
    @AppStorage(AppSettings.fontFamilyKey) private var fontFamily = AppSettings.defaultFontFamily
    @AppStorage(AppSettings.fontSizeKey) private var fontSize = AppSettings.defaultFontSize

    var body: some View {
        Form {
            Picker("Font", selection: $fontFamily) {
                Text("System").tag(".AppleSystemUIFont")
                Text("New York").tag("New York")
                Text("Georgia").tag("Georgia")
                Text("SF Mono").tag("SF Mono")
            }
            Stepper(value: $fontSize, in: AppSettings.minimumFontSize...AppSettings.maximumFontSize, step: 1) {
                Text("Size \(Int(fontSize))")
            }
        }
        .formStyle(.grouped)
    }
}

struct TemplatesSettingsView: View {
    @Environment(DodoStores.self) private var stores
    @State private var name = ""
    @State private var bodyMarkdown = ""

    var body: some View {
        VStack(alignment: .leading) {
            List {
                ForEach(stores.notes.templates()) { template in
                    VStack(alignment: .leading) {
                        TextField("Name", text: Binding(
                            get: { template.name },
                            set: { try? stores.notes.updateTemplate(template, name: $0) }
                        ))
                        TextField("Body", text: Binding(
                            get: { template.bodyMarkdown },
                            set: { try? stores.notes.updateTemplate(template, bodyMarkdown: $0) }
                        ), axis: .vertical)
                        .lineLimit(2...6)
                    }
                }
                .onDelete { indexSet in
                    let templates = stores.notes.templates()
                    for index in indexSet {
                        try? stores.notes.deleteTemplate(templates[index])
                    }
                }
            }
            HStack {
                TextField("New template", text: $name)
                Button("Add") {
                    try? stores.notes.createTemplate(name: name, bodyMarkdown: bodyMarkdown)
                    name = ""
                    bodyMarkdown = ""
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            TextField("Template body", text: $bodyMarkdown, axis: .vertical)
                .lineLimit(2...4)
        }
        .padding()
    }
}

struct CategoriesSettingsView: View {
    @Environment(DodoStores.self) private var stores
    @State private var name = ""

    var body: some View {
        VStack(alignment: .leading) {
            List {
                ForEach(stores.notes.categories()) { category in
                    TextField("Name", text: Binding(
                        get: { category.name },
                        set: { try? stores.notes.renameCategory(category, to: $0) }
                    ))
                }
                .onDelete { indexSet in
                    let categories = stores.notes.categories()
                    for index in indexSet {
                        try? stores.notes.deleteCategory(categories[index])
                    }
                }
            }
            HStack {
                TextField("New category", text: $name)
                Button("Add") {
                    try? stores.notes.createCategory(name: name)
                    name = ""
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
    }
}

struct PrioritySettingsView: View {
    @AppStorage(AppSettings.priorityNoneKey) private var noneLabel = AppSettings.defaultPriorityNone
    @AppStorage(AppSettings.priorityLowKey) private var lowLabel = AppSettings.defaultPriorityLow
    @AppStorage(AppSettings.priorityMediumKey) private var mediumLabel = AppSettings.defaultPriorityMedium
    @AppStorage(AppSettings.priorityHighKey) private var highLabel = AppSettings.defaultPriorityHigh

    var body: some View {
        Form {
            TextField("None", text: $noneLabel)
            TextField("Low", text: $lowLabel)
            TextField("Medium", text: $mediumLabel)
            TextField("High", text: $highLabel)
        }
        .formStyle(.grouped)
    }
}

struct ComingLaterSettingsView: View {
    var body: some View {
        Form {
            comingLaterRow("Transcription", "Record meetings and turn them into notes.")
            comingLaterRow("Local LLM", "Daily action extraction with Ollama.")
            comingLaterRow("iCloud", "Sync notes and tasks with CloudKit.")
            comingLaterRow("Claude", "Search and capture through a local MCP server.")
        }
        .formStyle(.grouped)
    }

    private func comingLaterRow(_ title: String, _ detail: String) -> some View {
        LabeledContent {
            Text("Coming later")
                .foregroundStyle(.secondary)
        } label: {
            VStack(alignment: .leading) {
                Text(title)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .disabled(true)
    }
}
