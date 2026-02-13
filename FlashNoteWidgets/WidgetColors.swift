import SwiftUI
import UIKit

/// Editorial color palette for widgets (mirrors AppColors, standalone for widget target).
enum WidgetColors {
    static let accent = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.91, green: 0.27, blue: 0.23, alpha: 1)  // #E8453A
            : UIColor(red: 0.83, green: 0.22, blue: 0.17, alpha: 1)  // #D4382C
    })

    static let background = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.047, green: 0.047, blue: 0.047, alpha: 1)  // #0C0C0C
            : UIColor(red: 0.98, green: 0.98, blue: 0.97, alpha: 1)     // #FAFAF8
    }
}
