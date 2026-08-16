import AVFoundation
import WGCore

/// Narrow seam around `AVSpeechSynthesizer` so
/// `AVSpeechSynthesizerAudioPlayer` can be tested without triggering a
/// real utterance (docs/adr/0006) — same role as `WGAdapters.HTTPTransport`.
/// Internal: `AVFoundation` types must not leak through this module's
/// public interface (`Package.swift`'s review-enforced rule).
protocol SpeechSynthesizing: Sendable {
    func speak(_ utterance: AVSpeechUtterance)
    @discardableResult
    func pauseSpeaking(at boundary: AVSpeechBoundary) -> Bool
    @discardableResult
    func continueSpeaking() -> Bool
    @discardableResult
    func stopSpeaking(at boundary: AVSpeechBoundary) -> Bool
}

extension AVSpeechSynthesizer: SpeechSynthesizing {}

#if os(iOS)
/// Narrow seam around `AVAudioSession` — unlike `AVSpeechSynthesizer`,
/// `AVAudioSession` does not exist on macOS, so this whole seam (and its
/// use below) is iOS-only. This module also builds for macOS so `swift
/// test` can run without a simulator (docs/adr/0006); that means `swift
/// test` never compiles or exercises this code path — verified instead
/// by `xcodebuild build` against a real iOS destination (specs/014).
protocol AudioSessionConfiguring: Sendable {
    func setCategory(_ category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions) throws
    func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws
}

extension AVAudioSession: AudioSessionConfiguring {}
#endif

/// Speaks `AudioAsset.text` on-device via `AVSpeechSynthesizer`
/// (docs/adr/0011, docs/adr/0013) — the first real `AudioPlaying`. `play`
/// starts synthesis and returns once initiated; it does not await the
/// utterance finishing, since the protocol has no completion signal.
public final class AVSpeechSynthesizerAudioPlayer: AudioPlaying, @unchecked Sendable {
    private let synthesizer: SpeechSynthesizing
    private let voiceResolver: (String) -> AVSpeechSynthesisVoice?
    #if os(iOS)
    private let audioSession: AudioSessionConfiguring
    #endif

    public convenience init() {
        #if os(iOS)
        self.init(
            synthesizer: AVSpeechSynthesizer(),
            voiceResolver: SpeechVoiceResolver.voice(forLanguageCode:),
            audioSession: AVAudioSession.sharedInstance()
        )
        #else
        self.init(synthesizer: AVSpeechSynthesizer(), voiceResolver: SpeechVoiceResolver.voice(forLanguageCode:))
        #endif
    }

    #if os(iOS)
    init(
        synthesizer: SpeechSynthesizing,
        voiceResolver: @escaping (String) -> AVSpeechSynthesisVoice?,
        audioSession: AudioSessionConfiguring
    ) {
        self.synthesizer = synthesizer
        self.voiceResolver = voiceResolver
        self.audioSession = audioSession
    }
    #else
    init(synthesizer: SpeechSynthesizing, voiceResolver: @escaping (String) -> AVSpeechSynthesisVoice?) {
        self.synthesizer = synthesizer
        self.voiceResolver = voiceResolver
    }
    #endif

    public func play(_ asset: AudioAsset) async throws {
        // .playback + .spokenAudio is what tells iOS this audio should
        // keep going once the app is backgrounded (docs/adr paired with
        // UIBackgroundModes: [audio] in ios/project.yml) rather than be
        // suspended like any other background app.
        #if os(iOS)
        try? audioSession.setCategory(.playback, mode: .spokenAudio, options: [])
        try? audioSession.setActive(true, options: [])
        #endif

        let utterance = AVSpeechUtterance(string: asset.text)
        utterance.voice = voiceResolver(asset.language)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * asset.rateMultiplier
        utterance.pitchMultiplier = 1.02
        utterance.prefersAssistiveTechnologySettings = true
        synthesizer.speak(utterance)
    }

    public func pause() async {
        // Deliberately does not touch the audio session — deactivating
        // on pause would drop the route/Now Playing state a user expects
        // to still control (e.g. from Control Center) while paused.
        synthesizer.pauseSpeaking(at: .word)
    }

    public func resume() async {
        synthesizer.continueSpeaking()
    }

    public func stop() async {
        synthesizer.stopSpeaking(at: .immediate)
        #if os(iOS)
        try? audioSession.setActive(false, options: [.notifyOthersOnDeactivation])
        #endif
    }
}
