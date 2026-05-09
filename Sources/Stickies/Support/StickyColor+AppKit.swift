import AppKit
import StickiesCore
import SwiftUI

extension StickyColor {
    var nsColor: NSColor {
        switch self {
        case .yellow:
            NSColor(calibratedRed: 1.00, green: 0.92, blue: 0.45, alpha: 1.00)
        case .blue:
            NSColor(calibratedRed: 0.65, green: 0.84, blue: 1.00, alpha: 1.00)
        case .green:
            NSColor(calibratedRed: 0.72, green: 0.93, blue: 0.66, alpha: 1.00)
        case .pink:
            NSColor(calibratedRed: 1.00, green: 0.70, blue: 0.83, alpha: 1.00)
        case .graphite:
            NSColor(calibratedRed: 0.74, green: 0.75, blue: 0.78, alpha: 1.00)
        }
    }

    var swiftUIColor: Color {
        Color(nsColor: nsColor)
    }
}

