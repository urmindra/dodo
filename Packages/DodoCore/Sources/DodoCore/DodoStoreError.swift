import Foundation

public enum DodoStoreError: Error, Equatable {
    case emptyTitle
    case duplicateName
    case invalidURL
    case missing
}
