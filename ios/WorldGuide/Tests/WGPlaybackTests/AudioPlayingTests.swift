import XCTest
import Foundation
@testable import WGPlayback

private actor FakeAudioPlayer: AudioPlaying {
    private(set) var playedAssets: [AudioAsset] = []
    private(set) var pauseCallCount = 0
    private(set) var resumeCallCount = 0
    private(set) var stopCallCount = 0

    func play(_ asset: AudioAsset) async throws {
        playedAssets.append(asset)
    }

    func pause() async {
        pauseCallCount += 1
    }

    func resume() async {
        resumeCallCount += 1
    }

    func stop() async {
        stopCallCount += 1
    }
}

final class AudioPlayingTests: XCTestCase {
    func testFakePlayerRecordsPlayedAsset() async throws {
        let player = FakeAudioPlayer()
        let asset = AudioAsset(id: "speech-1", text: "Bonjour", language: "fr")

        try await player.play(asset)

        let played = await player.playedAssets
        XCTAssertEqual(played, [asset])
    }

    func testFakePlayerRecordsStopCalls() async throws {
        let player = FakeAudioPlayer()

        await player.stop()

        let count = await player.stopCallCount
        XCTAssertEqual(count, 1)
    }

    func testFakePlayerRecordsPauseAndResumeCalls() async throws {
        let player = FakeAudioPlayer()

        await player.pause()
        await player.resume()

        let pauseCount = await player.pauseCallCount
        let resumeCount = await player.resumeCallCount
        XCTAssertEqual(pauseCount, 1)
        XCTAssertEqual(resumeCount, 1)
    }
}
