import AVFoundation

/// Resolves a stored language code (the Wikipedia language subdomain,
/// e.g. "fr", "en", "zh-hans" — docs/adr/0011) to an installed system
/// voice, since `AVSpeechSynthesisVoice(language:)` expects an exact
/// BCP-47 tag (e.g. "fr-FR") that rarely matches directly, and only ever
/// returns the OS default voice for that language — never the specific
/// (possibly higher-quality) voice this resolver found.
enum SpeechVoiceResolver {
    /// Decoupled from `AVSpeechSynthesisVoice` so `bestMatch` stays
    /// testable without real installed voices (which vary by
    /// machine/CI runner, and whose *quality* varies even more: Enhanced/
    /// Premium voices are a separate download, absent by default).
    struct Candidate: Equatable {
        let identifier: String
        let language: String
        let qualityRank: Int
    }

    static func voice(forLanguageCode code: String) -> AVSpeechSynthesisVoice? {
        let candidates = AVSpeechSynthesisVoice.speechVoices().map {
            Candidate(identifier: $0.identifier, language: $0.language, qualityRank: $0.quality.rawValue)
        }
        guard let matched = bestMatch(forLanguageCode: code, availableVoices: candidates) else {
            return nil
        }
        return AVSpeechSynthesisVoice(identifier: matched.identifier)
    }

    /// Pure — tested against plain candidate values, not the device's
    /// actual installed voices.
    static func bestMatch(forLanguageCode code: String, availableVoices: [Candidate]) -> Candidate? {
        for prefix in preferredPrefixes(forLanguageCode: code) {
            let matches = availableVoices.filter { $0.language.lowercased().hasPrefix(prefix.lowercased()) }
            // Prefer the highest-quality match (Premium > Enhanced >
            // Default) rather than an arbitrary one — found via a real
            // "the voice sounds robotic" report where a Default-quality
            // voice was picked despite better ones sometimes being
            // available.
            if let best = matches.max(by: { $0.qualityRank < $1.qualityRank }) {
                return best
            }
        }
        return nil
    }

    // docs/adr/0011's own flagged example: Wikipedia's "zh-hans"/"zh-hant"
    // variant codes don't share a BCP-47 prefix with the regional tags
    // (zh-CN, zh-TW, ...) real voices use, so a plain prefix match can't
    // find them without this mapping.
    private static let specialCasePrefixes: [String: [String]] = [
        "zh-hans": ["zh-CN", "zh-SG", "zh"],
        "zh-hant": ["zh-TW", "zh-HK", "zh"],
    ]

    private static func preferredPrefixes(forLanguageCode code: String) -> [String] {
        if let special = specialCasePrefixes[code.lowercased()] {
            return special
        }
        let base = code.split(separator: "-").first.map(String.init) ?? code
        return base.lowercased() == code.lowercased() ? [code] : [code, base]
    }
}
