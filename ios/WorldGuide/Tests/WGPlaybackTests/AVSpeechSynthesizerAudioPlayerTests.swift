import XCTest
import AVFoundation
@testable import WGPlayback

private final class FakeSpeechSynthesizer: SpeechSynthesizing, @unchecked Sendable {
    private(set) var spokenUtterances: [AVSpeechUtterance] = []
    private(set) var pauseBoundaries: [AVSpeechBoundary] = []
    private(set) var continueCallCount = 0
    private(set) var stopBoundaries: [AVSpeechBoundary] = []

    func speak(_ utterance: AVSpeechUtterance) {
        spokenUtterances.append(utterance)
    }

    func pauseSpeaking(at boundary: AVSpeechBoundary) -> Bool {
        pauseBoundaries.append(boundary)
        return true
    }

    func continueSpeaking() -> Bool {
        continueCallCount += 1
        return true
    }

    func stopSpeaking(at boundary: AVSpeechBoundary) -> Bool {
        stopBoundaries.append(boundary)
        return true
    }
}

final class AVSpeechSynthesizerAudioPlayerTests: XCTestCase {
    func testPlaySpeaksTheAssetTextWithAResolvedVoice() async throws {
        let synthesizer = FakeSpeechSynthesizer()
        let voice = AVSpeechSynthesisVoice(language: "en-US")
        let player = AVSpeechSynthesizerAudioPlayer(synthesizer: synthesizer, voiceResolver: { _ in voice })

        try await player.play(AudioAsset(id: "a1", text: "Hello there", language: "en"))

        XCTAssertEqual(synthesizer.spokenUtterances.map(\.speechString), ["Hello there"])
        XCTAssertEqual(synthesizer.spokenUtterances.first?.voice, voice)
    }

    func testPlayUsesNaturalSpeechSettings() async throws {
        let synthesizer = FakeSpeechSynthesizer()
        let player = AVSpeechSynthesizerAudioPlayer(synthesizer: synthesizer, voiceResolver: { _ in nil })

        try await player.play(AudioAsset(id: "a1", text: "Bonjour", language: "fr"))

        let utterance = try XCTUnwrap(synthesizer.spokenUtterances.first)
        XCTAssertEqual(utterance.rate, AVSpeechUtteranceDefaultSpeechRate * 0.92, accuracy: 0.001)
        XCTAssertEqual(utterance.pitchMultiplier, 1.02, accuracy: 0.001)
        XCTAssertTrue(utterance.prefersAssistiveTechnologySettings)
    }

    func testPlayUsesNilVoiceWhenResolverFindsNoMatch() async throws {
        let synthesizer = FakeSpeechSynthesizer()
        let player = AVSpeechSynthesizerAudioPlayer(synthesizer: synthesizer, voiceResolver: { _ in nil })

        try await player.play(AudioAsset(id: "a1", text: "Bonjour", language: "fr"))

        XCTAssertNil(synthesizer.spokenUtterances.first?.voice)
    }

    func testStopStopsImmediately() async throws {
        let synthesizer = FakeSpeechSynthesizer()
        let player = AVSpeechSynthesizerAudioPlayer(synthesizer: synthesizer, voiceResolver: { _ in nil })

        await player.stop()

        XCTAssertEqual(synthesizer.stopBoundaries, [.immediate])
    }

    func testPausePausesAtAWordBoundary() async throws {
        // .word, not .immediate: pausing mid-word would clip audio the
        // user is currently hearing.
        let synthesizer = FakeSpeechSynthesizer()
        let player = AVSpeechSynthesizerAudioPlayer(synthesizer: synthesizer, voiceResolver: { _ in nil })

        await player.pause()

        XCTAssertEqual(synthesizer.pauseBoundaries, [.word])
    }

    func testResumeContinuesSpeaking() async throws {
        let synthesizer = FakeSpeechSynthesizer()
        let player = AVSpeechSynthesizerAudioPlayer(synthesizer: synthesizer, voiceResolver: { _ in nil })

        await player.resume()

        XCTAssertEqual(synthesizer.continueCallCount, 1)
    }
}
