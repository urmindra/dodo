import Foundation

enum TrimmedText {
    static func name(_ raw: String) throws -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            throw DodoStoreError.emptyTitle
        }
        return trimmed
    }

    static func optionalLabel(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return nil
        }
        return trimmed
    }
}

enum LinkURL {
    static func parse(_ raw: String) throws -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            throw DodoStoreError.invalidURL
        }

        guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased() else {
            throw DodoStoreError.invalidURL
        }

        switch scheme {
        case "http", "https":
            if url.host == nil || url.host?.isEmpty == true {
                throw DodoStoreError.invalidURL
            }
        case "file":
            break
        default:
            throw DodoStoreError.invalidURL
        }

        return trimmed
    }
}

enum NameMatch {
    static func equals(_ left: String, _ right: String) -> Bool {
        left.compare(right, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
    }
}
