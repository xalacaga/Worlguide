public enum WGError: Error, Sendable, Equatable {
    case network(String)
    case decoding(String)
    case notFound
    case permissionDenied
}
