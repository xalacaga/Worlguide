/// The concrete implementation (`AVSpeechSynthesizerAudioPlayer`,
/// docs/adr/0011, docs/adr/0013) lives in this module — `AVFoundation`
/// compiles, links, and runs fine via plain `swift build`/`swift test` on
/// macOS, no App target or simulator required (verified before specs/010).
public protocol AudioPlaying: Sendable {
    func play(_ asset: AudioAsset) async throws
    /// Pauses in place — a subsequent `resume()` continues from here, not
    /// from the start (unlike `stop()`, which discards playback position).
    func pause() async
    func resume() async
    func stop() async
}
