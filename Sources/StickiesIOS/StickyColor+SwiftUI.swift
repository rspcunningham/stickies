import StickiesCore
import SwiftUI

extension StickyColor {
    var swiftUIColor: Color {
        switch self {
        case .yellow:
            Color(red: 1.00, green: 0.92, blue: 0.45)
        case .blue:
            Color(red: 0.65, green: 0.84, blue: 1.00)
        case .green:
            Color(red: 0.72, green: 0.93, blue: 0.66)
        case .pink:
            Color(red: 1.00, green: 0.70, blue: 0.83)
        case .graphite:
            Color(red: 0.74, green: 0.75, blue: 0.78)
        }
    }

    var title: String {
        switch self {
        case .yellow:
            "Yellow"
        case .blue:
            "Blue"
        case .green:
            "Green"
        case .pink:
            "Pink"
        case .graphite:
            "Graphite"
        }
    }
}
