/// Text to speak on-device, not a pre-rendered audio file — there is no
/// backend to render one (docs/adr/0012). Carries `AVSpeechSynthesizer`'s
/// actual inputs (docs/adr/0011, docs/adr/0013): `id` still identifies a
/// specific playback request for correlation/logging.
public struct AudioAsset: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let text: String
    public let language: String
    public let rateMultiplier: Float

    public init(id: String, text: String, language: String, rateMultiplier: Float = 0.92) {
        self.id = id
        self.text = text
        self.language = language
        self.rateMultiplier = rateMultiplier
    }
}
