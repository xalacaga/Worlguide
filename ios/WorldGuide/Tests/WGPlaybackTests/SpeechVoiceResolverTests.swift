import XCTest
@testable import WGPlayback

private typealias Candidate = SpeechVoiceResolver.Candidate

private func candidate(_ identifier: String, _ language: String, quality: Int = 1) -> Candidate {
    Candidate(identifier: identifier, language: language, qualityRank: quality)
}

final class SpeechVoiceResolverTests: XCTestCase {
    private let availableVoices = [
        candidate("en-US-voice", "en-US"),
        candidate("fr-FR-voice", "fr-FR"),
        candidate("de-DE-voice", "de-DE"),
        candidate("zh-CN-voice", "zh-CN"),
        candidate("zh-TW-voice", "zh-TW"),
        candidate("es-ES-voice", "es-ES"),
    ]

    func testBestMatchFindsAVoiceByBareLanguagePrefix() {
        let match = SpeechVoiceResolver.bestMatch(forLanguageCode: "fr", availableVoices: availableVoices)

        XCTAssertEqual(match?.language, "fr-FR")
    }

    func testBestMatchFindsAVoiceByExactCode() {
        let match = SpeechVoiceResolver.bestMatch(forLanguageCode: "de-DE", availableVoices: availableVoices)

        XCTAssertEqual(match?.language, "de-DE")
    }

    func testBestMatchPrefersSimplifiedChineseVoiceForZhHans() {
        let match = SpeechVoiceResolver.bestMatch(forLanguageCode: "zh-hans", availableVoices: availableVoices)

        XCTAssertEqual(match?.language, "zh-CN")
    }

    func testBestMatchPrefersTraditionalChineseVoiceForZhHant() {
        let match = SpeechVoiceResolver.bestMatch(forLanguageCode: "zh-hant", availableVoices: availableVoices)

        XCTAssertEqual(match?.language, "zh-TW")
    }

    func testBestMatchFallsBackToBareZhWhenRegionalVariantMissing() {
        let match = SpeechVoiceResolver.bestMatch(
            forLanguageCode: "zh-hans",
            availableVoices: [candidate("zh-HK-voice", "zh-HK"), candidate("en-US-voice", "en-US")]
        )

        XCTAssertEqual(match?.language, "zh-HK")
    }

    func testBestMatchReturnsNilWhenNothingMatches() {
        let match = SpeechVoiceResolver.bestMatch(forLanguageCode: "ja", availableVoices: availableVoices)

        XCTAssertNil(match)
    }

    func testBestMatchPrefersHigherQualityVoiceOverAnArbitraryMatch() {
        let voices = [
            candidate("en-US-compact", "en-US", quality: 1),
            candidate("en-US-enhanced", "en-US", quality: 2),
            candidate("en-US-premium", "en-US", quality: 3),
        ]

        let match = SpeechVoiceResolver.bestMatch(forLanguageCode: "en", availableVoices: voices)

        XCTAssertEqual(match?.identifier, "en-US-premium")
    }
}
