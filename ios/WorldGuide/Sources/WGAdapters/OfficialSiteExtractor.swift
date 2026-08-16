import Foundation
import WGCore

/// Extracts a short readable card from an official/tourism website. This is
/// intentionally bounded: metadata + first meaningful paragraphs, not a
/// full website mirror.
public struct OfficialSiteExtractor: Sendable {
    public struct ExtractedContent: Sendable, Equatable {
        public let url: URL
        public let title: String
        public let text: String
        public let language: String?
        public let priceHint: String?

        public init(url: URL, title: String, text: String, language: String?, priceHint: String?) {
            self.url = url
            self.title = title
            self.text = text
            self.language = language
            self.priceHint = priceHint
        }
    }

    private static let userAgent = "WorldGuide-iOS/0.1 (official-source extractor; no contact URL yet)"
    private static let requestTimeoutSeconds: TimeInterval = 8
    private static let requestedByteLimit = 160_000

    private let transport: HTTPTransport

    public init(transport: HTTPTransport = URLSession.shared) {
        self.transport = transport
    }

    public func content(from url: URL) async throws -> ExtractedContent? {
        var request = URLRequest(url: url)
        request.timeoutInterval = Self.requestTimeoutSeconds
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")
        request.setValue("bytes=0-\(Self.requestedByteLimit - 1)", forHTTPHeaderField: "Range")
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await transport.data(for: request)
        } catch {
            throw WGError.network(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw WGError.network("Official site request failed with status \(status)")
        }
        guard let html = Self.decodeHTML(data: data, response: httpResponse) else {
            throw WGError.decoding("Could not decode official site HTML")
        }
        return Self.extract(fromHTML: html, url: url)
    }

    public static func extract(fromHTML html: String, url: URL) -> ExtractedContent? {
        let stripped = stripNonContentBlocks(from: html)
        let title = clean(firstMatch(in: stripped, pattern: #"<title[^>]*>(.*?)</title>"#))
        let description = clean(metaContent(in: stripped, names: ["description", "og:description", "twitter:description"]))
        let paragraphs = paragraphTexts(from: stripped)
        let text = ([description] + paragraphs).compactMap { $0 }.uniqued().prefix(3).joined(separator: "\n\n")
        let language = normalizedLanguageCode(firstMatch(in: stripped, pattern: #"<html[^>]+lang=["']([^"']+)["']"#))
        let priceHint = firstPriceHint(in: stripped)

        guard !text.isEmpty else { return nil }
        return ExtractedContent(
            url: url,
            title: title ?? hostTitle(from: url),
            text: String(text.prefix(1_200)),
            language: language,
            priceHint: priceHint
        )
    }

    private static func decodeHTML(data: Data, response: HTTPURLResponse) -> String? {
        let head = String(data: data.prefix(4_096), encoding: .ascii) ?? ""
        let declaredCharset = response.value(forHTTPHeaderField: "Content-Type")
            .flatMap(charset(fromContentType:)) ?? charset(fromHTMLHead: head)
        if let encoding = declaredCharset.flatMap(stringEncoding(forCharset:)),
           let decoded = String(data: data, encoding: encoding) {
            return decoded
        }
        return String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1)
    }

    private static func charset(fromContentType contentType: String) -> String? {
        firstMatch(in: contentType, pattern: #"charset\s*=\s*["']?([^;"'\s]+)"#)
    }

    private static func charset(fromHTMLHead htmlHead: String) -> String? {
        firstMatch(in: htmlHead, pattern: #"<meta[^>]+charset\s*=\s*["']?([^"'\s/>]+)"#)
    }

    private static func stringEncoding(forCharset charset: String) -> String.Encoding? {
        switch charset.lowercased().replacingOccurrences(of: "_", with: "-") {
        case "utf-8", "utf8":
            return .utf8
        case "iso-8859-1", "latin1", "latin-1":
            return .isoLatin1
        case "windows-1252", "cp1252":
            return .windowsCP1252
        default:
            return nil
        }
    }

    private static func stripNonContentBlocks(from html: String) -> String {
        html
            .replacingOccurrences(of: #"<script[\s\S]*?</script>"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"<style[\s\S]*?</style>"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"<noscript[\s\S]*?</noscript>"#, with: " ", options: .regularExpression)
    }

    private static func paragraphTexts(from html: String) -> [String] {
        allMatches(in: html, pattern: #"<p[^>]*>(.*?)</p>"#)
            .compactMap(clean)
            .filter { $0.count >= 60 }
    }

    private static func metaContent(in html: String, names: [String]) -> String? {
        for name in names {
            let escapedName = NSRegularExpression.escapedPattern(for: name)
            let patterns = [
                #"<meta[^>]+(?:name|property)=["']\#(escapedName)["'][^>]+content=["']([^"']+)["'][^>]*>"#,
                #"<meta[^>]+content=["']([^"']+)["'][^>]+(?:name|property)=["']\#(escapedName)["'][^>]*>"#,
            ]
            for pattern in patterns {
                if let match = firstMatch(in: html, pattern: pattern) {
                    return match
                }
            }
        }
        return nil
    }

    private static func firstPriceHint(in html: String) -> String? {
        let text = clean(html.replacingOccurrences(of: #"<[^>]+>"#, with: " ", options: .regularExpression)) ?? ""
        let patterns = [
            #"(?:€|\$|£)\s?\d+(?:[,.]\d{1,2})?"#,
            #"\d+(?:[,.]\d{1,2})?\s?(?:€|EUR|euros?)"#,
            #"(?i)(free admission|entrée gratuite|gratuit|tarif[^.]{0,80})"#,
        ]
        for pattern in patterns {
            if let match = firstMatch(in: text, pattern: pattern, captureGroup: 0) {
                return clean(match)
            }
        }
        return nil
    }

    private static func firstMatch(in html: String, pattern: String, captureGroup: Int = 1) -> String? {
        allMatches(in: html, pattern: pattern, captureGroup: captureGroup).first
    }

    private static func allMatches(in html: String, pattern: String, captureGroup: Int = 1) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return []
        }
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        return regex.matches(in: html, range: range).compactMap { match in
            guard match.numberOfRanges > captureGroup,
                  let captureRange = Range(match.range(at: captureGroup), in: html) else {
                return nil
            }
            return String(html[captureRange])
        }
    }

    private static func clean(_ value: String?) -> String? {
        guard let value else { return nil }
        let withoutTags = value.replacingOccurrences(of: #"<[^>]+>"#, with: " ", options: .regularExpression)
        let decoded = decodedHTMLEntities(in: withoutTags)
        let collapsed = decoded.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        let trimmed = collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func decodedHTMLEntities(in value: String) -> String {
        var decoded = value
        let namedEntities: [String: String] = [
            "&amp;": "&",
            "&quot;": "\"",
            "&apos;": "'",
            "&nbsp;": " ",
            "&lt;": "<",
            "&gt;": ">",
            "&rsquo;": "'",
            "&lsquo;": "'",
            "&rdquo;": "\"",
            "&ldquo;": "\"",
            "&ndash;": "-",
            "&mdash;": "-",
            "&hellip;": "...",
            "&euro;": "€",
            "&agrave;": "à",
            "&acirc;": "â",
            "&auml;": "ä",
            "&aelig;": "æ",
            "&ccedil;": "ç",
            "&egrave;": "è",
            "&eacute;": "é",
            "&ecirc;": "ê",
            "&euml;": "ë",
            "&icirc;": "î",
            "&iuml;": "ï",
            "&ocirc;": "ô",
            "&ouml;": "ö",
            "&ugrave;": "ù",
            "&ucirc;": "û",
            "&uuml;": "ü",
            "&Agrave;": "À",
            "&Eacute;": "É",
            "&OElig;": "Œ",
            "&oelig;": "œ",
        ]
        for (entity, replacement) in namedEntities {
            decoded = decoded.replacingOccurrences(of: entity, with: replacement)
        }
        decoded = replaceMatches(in: decoded, pattern: #"&#(\d+);"#) { match in
            guard let value = Int(match.dropFirst(2).dropLast()),
                  let scalar = UnicodeScalar(value) else { return match }
            return String(scalar)
        }
        decoded = replaceMatches(in: decoded, pattern: #"&#x([0-9A-Fa-f]+);"#) { match in
            let hex = match.dropFirst(3).dropLast()
            guard let value = Int(hex, radix: 16),
                  let scalar = UnicodeScalar(value) else { return match }
            return String(scalar)
        }
        return decoded
    }

    private static func replaceMatches(in value: String, pattern: String, replacement: (String) -> String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return value }
        let matches = regex.matches(in: value, range: NSRange(value.startIndex..<value.endIndex, in: value))
        guard !matches.isEmpty else { return value }

        var result = ""
        var currentIndex = value.startIndex
        for match in matches {
            guard let range = Range(match.range, in: value) else { continue }
            result += value[currentIndex..<range.lowerBound]
            result += replacement(String(value[range]))
            currentIndex = range.upperBound
        }
        result += value[currentIndex..<value.endIndex]
        return result
    }

    private static func normalizedLanguageCode(_ value: String?) -> String? {
        guard let language = value?.split(separator: "-").first?.lowercased(), language.isEmpty == false else {
            return nil
        }
        return language
    }

    private static func hostTitle(from url: URL) -> String {
        url.host?.replacingOccurrences(of: "www.", with: "") ?? "Official source"
    }
}

private extension Sequence where Element == String {
    func uniqued() -> [String] {
        var seen = Set<String>()
        return filter { seen.insert($0).inserted }
    }
}
