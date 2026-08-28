import SwiftUI
import DodoCore

struct EditorTypography {
    static func font(family: String, size: Double) -> Font {
        if family == ".AppleSystemUIFont" {
            return .system(size: size)
        }
        return .custom(family, size: size)
    }
}

struct MarkdownPane: View {
    @Binding var text: String
    @AppStorage(AppSettings.fontFamilyKey) private var fontFamily = AppSettings.defaultFontFamily
    @AppStorage(AppSettings.fontSizeKey) private var fontSize = AppSettings.defaultFontSize
    @State private var mode = Mode.edit

    enum Mode: String, CaseIterable {
        case edit = "Edit"
        case preview = "Preview"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Markdown", selection: $mode) {
                ForEach(Mode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 220)

            if mode == .edit {
                TextEditor(text: $text)
                    .font(EditorTypography.font(family: fontFamily, size: fontSize))
                    .scrollContentBackground(.hidden)
            } else {
                ScrollView {
                    Text(preview)
                        .font(EditorTypography.font(family: fontFamily, size: fontSize))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(.top, 4)
                }
            }
        }
    }

    private var preview: AttributedString {
        (try? AttributedString(
            markdown: text,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(text)
    }
}
