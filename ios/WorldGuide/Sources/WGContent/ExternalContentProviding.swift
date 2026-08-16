import WGCore

/// Port for optional external official information. Implementations may
/// fetch official/tourism/institutional pages, but app code only depends on
/// this async interface.
public protocol ExternalContentProviding: Sendable {
    func externalContent(forPOI poiID: String, coordinate: Coordinate?, language: String) async throws -> ExternalContentPackage?
}
