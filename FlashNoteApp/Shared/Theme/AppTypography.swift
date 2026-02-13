import SwiftUI

public enum AppTypography {

    // MARK: - Editorial Hierarchy
    //
    // Headlines: Serif (New York) — gravitas, editorial authority
    // Body:      Default (San Francisco) — clean readability
    // Metadata:  Monospaced (SF Mono) — precision, technical utility

    // MARK: - Headlines (Serif)

    public static let largeTitle = Font.system(.largeTitle, design: .serif, weight: .bold)
    public static let title = Font.system(.title, design: .serif, weight: .bold)
    public static let title2 = Font.system(.title2, design: .serif, weight: .semibold)
    public static let title3 = Font.system(.title3, design: .serif, weight: .semibold)

    // MARK: - Body & UI (Default)

    public static let headline = Font.system(.headline, design: .default, weight: .semibold)
    public static let body = Font.system(.body, design: .default)
    public static let callout = Font.system(.callout, design: .default)
    public static let subheadline = Font.system(.subheadline, design: .default, weight: .medium)

    // MARK: - Metadata (Monospaced)

    public static let footnote = Font.system(.footnote, design: .monospaced)
    public static let caption = Font.system(.caption, design: .monospaced)
    public static let captionSmall = Font.system(.caption2, design: .monospaced)

    // MARK: - Capture (Serif for intentional writing feel)

    public static let captureInput = Font.system(.title3, design: .serif, weight: .regular)
    public static let captureHint = Font.system(.title3, design: .serif, weight: .regular)

    // MARK: - Note Display

    public static let notePreview = Font.system(.body, design: .default)
    public static let noteTimestamp = Font.system(.caption, design: .monospaced)

    // MARK: - Section Headers (Uppercase monospace — editorial section dividers)

    public static let sectionHeader = Font.system(.caption, design: .monospaced, weight: .semibold)
}
