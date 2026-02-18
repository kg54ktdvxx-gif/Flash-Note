import Foundation

/// Platform-agnostic color values shared across App and Widget targets.
/// Both AppColors and WidgetColors reference these so the values stay in sync.
public enum DesignTokens {
    public struct AdaptiveRGB: Sendable {
        public let lightR: Double, lightG: Double, lightB: Double
        public let darkR: Double, darkG: Double, darkB: Double

        public init(
            lightR: Double, lightG: Double, lightB: Double,
            darkR: Double, darkG: Double, darkB: Double
        ) {
            self.lightR = lightR
            self.lightG = lightG
            self.lightB = lightB
            self.darkR = darkR
            self.darkG = darkG
            self.darkB = darkB
        }
    }

    // MARK: - Accent

    public static let accent = AdaptiveRGB(
        lightR: 0.83, lightG: 0.22, lightB: 0.17,     // #D4382C
        darkR: 0.91, darkG: 0.27, darkB: 0.23          // #E8453A
    )

    // MARK: - Background

    public static let background = AdaptiveRGB(
        lightR: 0.98, lightG: 0.98, lightB: 0.97,      // #FAFAF8
        darkR: 0.047, darkG: 0.047, darkB: 0.047       // #0C0C0C
    )
}
