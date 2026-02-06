import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public enum AppColors {
    // MARK: - Primary
    public static let primary = Color.blue
    public static let primarySoft = Color.blue.opacity(0.12)

    // MARK: - Calm ADHD-Friendly Palette
    public static let warmBackground = Color(red: 0.98, green: 0.97, blue: 0.95)
    public static let coolBackground = Color(red: 0.95, green: 0.96, blue: 0.98)

    // MARK: - Semantic
    #if canImport(UIKit)
    public static let captureBackground = Color(uiColor: .systemBackground)
    public static let inboxBackground = Color(uiColor: .systemGroupedBackground)
    public static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    public static let textPrimary = Color(uiColor: .label)
    public static let textSecondary = Color(uiColor: .secondaryLabel)
    public static let textTertiary = Color(uiColor: .tertiaryLabel)
    #else
    public static let captureBackground = Color.white
    public static let inboxBackground = Color.gray.opacity(0.1)
    public static let cardBackground = Color.gray.opacity(0.05)
    public static let textPrimary = Color.primary
    public static let textSecondary = Color.secondary
    public static let textTertiary = Color.gray
    #endif

    public static let textOnPrimary = Color.white

    // MARK: - Triage Actions
    public static let keepGreen = Color.green
    public static let archiveGray = Color.gray
    public static let taskOrange = Color.orange
    public static let deleteRed = Color.red

    // MARK: - Voice
    public static let waveformActive = Color.blue
    public static let waveformIdle = Color.gray.opacity(0.3)

    // MARK: - Status
    public static let success = Color.green
    public static let warning = Color.orange
    public static let error = Color.red
}
