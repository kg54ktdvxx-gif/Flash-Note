import SwiftUI

public enum AppTypography {
    // Large, readable text — ADHD-friendly with system rounded design
    public static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
    public static let title = Font.system(.title, design: .rounded, weight: .semibold)
    public static let title2 = Font.system(.title2, design: .rounded, weight: .semibold)
    public static let title3 = Font.system(.title3, design: .rounded, weight: .medium)
    public static let headline = Font.system(.headline, design: .rounded, weight: .semibold)
    public static let body = Font.system(.body, design: .rounded)
    public static let callout = Font.system(.callout, design: .rounded)
    public static let subheadline = Font.system(.subheadline, design: .rounded)
    public static let footnote = Font.system(.footnote, design: .rounded)
    public static let caption = Font.system(.caption, design: .rounded)

    // Capture-specific: larger text for the main input
    public static let captureInput = Font.system(.title3, design: .rounded, weight: .regular)
    public static let captureHint = Font.system(.title3, design: .rounded, weight: .regular)

    // Note preview in list
    public static let notePreview = Font.system(.body, design: .rounded)
    public static let noteTimestamp = Font.system(.caption, design: .rounded)
}
