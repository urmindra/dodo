import SwiftUI
import DodoCore

struct NoteEditorView: View {
    @Environment(DodoStores.self) private var stores
    @Environment(Workspace.self) private var workspace
    let note: Note
    @State private var title: String = ""
    @State private var bodyMarkdown: String = ""
    @State private var tagDraft = ""
    @State private var linkURL = ""
    @State private var linkLabel = ""
    @State private var linkError: String?
    @State private var selectedTemplateID: UUID?

    var body: some View {
        HSplitView {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Title", text: $title)
                    .textFieldStyle(.plain)
                    .font(.largeTitle)
                MarkdownPane(text: $bodyMarkdown)
            }
            .padding()
            .onChange(of: title) { _, newValue in
                try? stores.notes.updateNote(note, title: newValue)
            }
            .onChange(of: bodyMarkdown) { _, newValue in
                try? stores.notes.updateNote(note, bodyMarkdown: newValue)
            }

            noteInspector
                .frame(minWidth: 240, idealWidth: 280)
        }
        .onAppear(perform: load)
        .onChange(of: note.id) { _, _ in
            load()
        }
    }

    private var noteInspector: some View {
        Form {
            Section("Info") {
                LabeledContent("Created", value: note.createdAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Updated", value: note.updatedAt.formatted(date: .abbreviated, time: .shortened))
            }
            Section("Category") {
                Picker("Category", selection: categoryBinding) {
                    Text("None").tag(Optional<UUID>.none)
                    ForEach(stores.notes.categories()) { category in
                        Text(category.name).tag(Optional(category.id))
                    }
                }
            }
            Section("Tags") {
                ForEach(note.tags) { tag in
                    HStack {
                        Text(tag.name)
                        Spacer()
                        Button("Remove", role: .destructive) {
                            try? stores.notes.removeTag(tag, from: note)
                        }
                    }
                }
                HStack {
                    TextField("Add tag", text: $tagDraft)
                        .onSubmit(addTag)
                    Button("Add", action: addTag)
                }
            }
            Section("Links") {
                ForEach(note.links) { link in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(link.label ?? link.url)
                            if link.label != nil {
                                Text(link.url).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Button("Remove", role: .destructive) {
                            try? stores.notes.removeLink(link)
                        }
                    }
                }
                TextField("https://", text: $linkURL)
                TextField("Label (optional)", text: $linkLabel)
                Button("Add link", action: addLink)
                if let linkError {
                    Text(linkError).foregroundStyle(.red)
                }
            }
            Section("Template") {
                Picker("Insert template", selection: $selectedTemplateID) {
                    Text("Choose…").tag(Optional<UUID>.none)
                    ForEach(stores.notes.templates()) { template in
                        Text(template.name).tag(Optional(template.id))
                    }
                }
                Button("Apply") {
                    applyTemplate()
                }
                .disabled(selectedTemplateID == nil)
            }
            Section("Tasks") {
                ForEach(stores.tasks.tasks(linkedTo: note)) { task in
                    Button(task.title) {
                        workspace.show(task: task)
                    }
                }
                if stores.tasks.tasks(linkedTo: note).isEmpty {
                    Text("No linked tasks").foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding(.vertical)
    }

    private var categoryBinding: Binding<UUID?> {
        Binding(
            get: { note.category?.id },
            set: { id in
                let category = stores.notes.categories().first { $0.id == id }
                try? stores.notes.setCategory(category, on: note)
            }
        )
    }

    private func load() {
        title = note.title
        bodyMarkdown = note.bodyMarkdown
        tagDraft = ""
        linkURL = ""
        linkLabel = ""
        linkError = nil
    }

    private func addTag() {
        let name = tagDraft
        tagDraft = ""
        guard name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else { return }
        try? stores.notes.addTag(named: name, to: note)
    }

    private func addLink() {
        do {
            try stores.notes.addLink(url: linkURL, label: linkLabel, to: note)
            linkURL = ""
            linkLabel = ""
            linkError = nil
        } catch {
            linkError = "Use an http, https, or file URL."
        }
    }

    private func applyTemplate() {
        guard let id = selectedTemplateID,
              let template = stores.notes.templates().first(where: { $0.id == id }) else {
            return
        }
        try? stores.notes.apply(template: template, to: note)
        bodyMarkdown = note.bodyMarkdown
        selectedTemplateID = nil
    }
}
