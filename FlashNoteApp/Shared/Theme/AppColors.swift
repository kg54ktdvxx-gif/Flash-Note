import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public enum AppColors {
    // MARK: - Primary (Refined blue for dark mode)
    public static let primary = Color(red: 0.4, green: 0.6, blue: 1.0)
    public static let primarySoft = Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.15)

    // MARK: - Dark Mode Backgrounds
    public static let darkBackground = Color(red: 0.07, green: 0.07, blue: 0.09)
    public static let darkSurface = Color(red: 0.11, green: 0.11, blue: 0.13)
    public static let darkElevated = Color(red: 0.15, green: 0.15, blue: 0.17)

    // MARK: - Semantic
    public static let captureBackground = darkBackground
    public static let inboxBackground = darkBackground
    public static let cardBackground = darkSurface
    public static let cardElevated = darkElevated

    public static let textPrimary = Color.white
    public static let textSecondary = Color.white.opacity(0.7)
    public static let textTertiary = Color.white.opacity(0.45)

    public static let textOnPrimary = Color.white

    // MARK: - Borders & Dividers
    public static let border = Color.white.opacity(0.1)
    public static let divider = Color.white.opacity(0.08)

    // MARK: - Triage Actions (Softer for dark mode)
    public static let keepGreen = Color(red: 0.3, green: 0.85, blue: 0.5)
    public static let archiveGray = Color(red: 0.55, green: 0.55, blue: 0.6)
    public static let taskOrange = Color(red: 1.0, green: 0.7, blue: 0.3)
    public static let deleteRed = Color(red: 1.0, green: 0.4, blue: 0.4)

    // MARK: - Voice
    public static let waveformActive = primary
    public static let waveformIdle = Color.white.opacity(0.2)

    // MARK: - Status
    public static let success = Color(red: 0.3, green: 0.85, blue: 0.5)
    public static let warning = Color(red: 1.0, green: 0.7, blue: 0.3)
    public static let error = Color(red: 1.0, green: 0.4, blue: 0.4)
}
