import Foundation

public enum TaskDetectionService {
    private static let keywords = [
        "buy", "call", "email", "schedule", "remind", "book",
        "todo", "fix", "send", "pick up", "don't forget",
        "need to", "have to"
    ]

    private static let pattern: NSRegularExpression? = {
        let escaped = keywords.map { NSRegularExpression.escapedPattern(for: $0) }
        let joined = escaped.joined(separator: "|")
        return try? NSRegularExpression(pattern: "\\b(\(joined))\\b", options: .caseInsensitive)
    }()

    public static func looksLikeTask(_ text: String) -> Bool {
        guard let pattern else { return false }
        let range = NSRange(text.startIndex..., in: text)
        return pattern.firstMatch(in: text, range: range) != nil
    }
}
