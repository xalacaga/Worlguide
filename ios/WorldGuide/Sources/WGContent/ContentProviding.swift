public protocol ContentProviding: Sendable {
    func content(forPOI poiID: String, language: String) async throws -> ContentPackage?
}
