import SwiftUI
import FlashNoteCore
#if canImport(UIKit)
import UIKit
#endif

public enum AppColors {

    // MARK: - Adaptive Color Helper

    /// Creates a color that adapts between light and dark mode.
    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    private static func adaptive(
        lightR: CGFloat, lightG: CGFloat, lightB: CGFloat,
        darkR: CGFloat, darkG: CGFloat, darkB: CGFloat
    ) -> Color {
        adaptive(
            light: UIColor(red: lightR, green: lightG, blue: lightB, alpha: 1),
            dark: UIColor(red: darkR, green: darkG, blue: darkB, alpha: 1)
        )
    }

    // MARK: - Primary Accent (Vermillion — used with restraint)
    // Values sourced from DesignTokens (FlashNoteCore) — shared with widgets.

    static let accent = adaptive(
        lightR: DesignTokens.accent.lightR, lightG: DesignTokens.accent.lightG, lightB: DesignTokens.accent.lightB,
        darkR: DesignTokens.accent.darkR, darkG: DesignTokens.accent.darkG, darkB: DesignTokens.accent.darkB
    )

    static let accentSoft = adaptive(
        light: UIColor(red: 0.83, green: 0.22, blue: 0.17, alpha: 0.08),
        dark: UIColor(red: 0.91, green: 0.27, blue: 0.23, alpha: 0.12)
    )

    // Keep backward compat for callers using `primary`
    static let primary = accent
    static let primarySoft = accentSoft

    // MARK: - Backgrounds

    static let background = adaptive(
        lightR: DesignTokens.background.lightR, lightG: DesignTokens.background.lightG, lightB: DesignTokens.background.lightB,
        darkR: DesignTokens.background.darkR, darkG: DesignTokens.background.darkG, darkB: DesignTokens.background.darkB
    )

    static let surface = adaptive(
        lightR: 0.94, lightG: 0.94, lightB: 0.93,      // #F0F0EC
        darkR: 0.086, darkG: 0.086, darkB: 0.086       // #161616
    )

    static let elevated = adaptive(
        lightR: 0.91, lightG: 0.91, lightB: 0.89,      // #E8E8E4
        darkR: 0.118, darkG: 0.118, darkB: 0.118       // #1E1E1E
    )

    // Semantic aliases
    static let captureBackground = background
    static let inboxBackground = background
    static let cardBackground = surface
    static let cardElevated = elevated

    // Legacy aliases (referenced by existing views)
    static let darkBackground = background
    static let darkSurface = surface
    static let darkElevated = elevated

    // MARK: - Text

    static let textPrimary = adaptive(
        lightR: 0.10, lightG: 0.10, lightB: 0.10,      // #1A1A1A ink
        darkR: 0.94, darkG: 0.94, darkB: 0.93          // #F0F0EC off-white
    )

    static let textSecondary = adaptive(
        lightR: 0.36, lightG: 0.36, lightB: 0.36,      // #5C5C5C
        darkR: 0.63, darkG: 0.63, darkB: 0.63          // #A0A0A0
    )

    static let textTertiary = adaptive(
        lightR: 0.61, lightG: 0.61, lightB: 0.61,      // #9C9C9C
        darkR: 0.40, darkG: 0.40, darkB: 0.40          // #666666
    )

    static let textOnAccent = Color.white

    // Legacy alias
    static let textOnPrimary = textOnAccent

    // MARK: - Borders & Dividers

    static let border = adaptive(
        lightR: 0.82, lightG: 0.82, lightB: 0.80,      // #D0D0CC
        darkR: 0.165, darkG: 0.165, darkB: 0.165       // #2A2A2A
    )

    static let divider = adaptive(
        lightR: 0.88, lightG: 0.88, lightB: 0.86,      // #E0E0DC
        darkR: 0.133, darkG: 0.133, darkB: 0.133       // #222222
    )

    static let rule = adaptive(
        lightR: 0.10, lightG: 0.10, lightB: 0.10,      // near-black rule in light
        darkR: 0.94, darkG: 0.94, darkB: 0.93          // off-white rule in dark
    )

    // MARK: - Triage Actions

    static let keepGreen = adaptive(
        lightR: 0.13, lightG: 0.53, lightB: 0.28,      // #218747 forest
        darkR: 0.22, darkG: 0.65, darkB: 0.37          // #38A65E
    )

    static let archiveGray = adaptive(
        lightR: 0.55, lightG: 0.55, lightB: 0.55,      // #8C8C8C
        darkR: 0.55, darkG: 0.55, darkB: 0.55          // #8C8C8C
    )

    static let taskOrange = adaptive(
        lightR: 0.72, lightG: 0.45, lightB: 0.08,      // #B87314 amber
        darkR: 0.85, darkG: 0.55, darkB: 0.15          // #D98C26
    )

    static let deleteRed = accent

    // MARK: - Voice

    static let waveformActive = accent
    static let waveformIdle = adaptive(
        lightR: 0.82, lightG: 0.82, lightB: 0.80,
        darkR: 0.25, darkG: 0.25, darkB: 0.25
    )

    // MARK: - Status

    static let success = keepGreen
    static let warning = taskOrange
    static let error = accent
}
