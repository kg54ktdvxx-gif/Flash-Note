import SwiftUI
import UIKit
import FlashNoteCore

/// Editorial color palette for widgets — values sourced from DesignTokens (single source of truth).
enum WidgetColors {
    static let accent = Color(UIColor { traits in
        let v = DesignTokens.accent
        return traits.userInterfaceStyle == .dark
            ? UIColor(red: v.darkR, green: v.darkG, blue: v.darkB, alpha: 1)
            : UIColor(red: v.lightR, green: v.lightG, blue: v.lightB, alpha: 1)
    })

    static let background = UIColor { traits in
        let v = DesignTokens.background
        return traits.userInterfaceStyle == .dark
            ? UIColor(red: v.darkR, green: v.darkG, blue: v.darkB, alpha: 1)
            : UIColor(red: v.lightR, green: v.lightG, blue: v.lightB, alpha: 1)
    }
}
