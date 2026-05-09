import AppKit
import Foundation

enum EditorFontFamily: String, CaseIterable {
    case system
    case monospaced

    var title: String {
        switch self {
        case .system:
            "System"
        case .monospaced:
            "Monospaced"
        }
    }

    func font(size: CGFloat) -> NSFont {
        switch self {
        case .system:
            NSFont.systemFont(ofSize: size)
        case .monospaced:
            NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
        }
    }
}

enum EditorPreferences {
    static let fontFamilyKey = "editorFontFamily"
    static let fontSizeKey = "editorFontSize"

    static let defaultFontFamily = EditorFontFamily.monospaced
    static let defaultFontSize = 15.0
    static let minimumFontSize = 10.0
    static let maximumFontSize = 28.0
    static let fontSizeStep = 1.0

    static var fontFamily: EditorFontFamily {
        get {
            let rawValue = UserDefaults.standard.string(forKey: fontFamilyKey)
            return rawValue.flatMap(EditorFontFamily.init(rawValue:)) ?? defaultFontFamily
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: fontFamilyKey)
        }
    }

    static var fontSize: Double {
        get {
            let storedSize = UserDefaults.standard.double(forKey: fontSizeKey)
            guard storedSize > 0 else {
                return defaultFontSize
            }

            return clampedFontSize(storedSize)
        }
        set {
            UserDefaults.standard.set(clampedFontSize(newValue), forKey: fontSizeKey)
        }
    }

    static func clampedFontSize(_ size: Double) -> Double {
        min(max(size, minimumFontSize), maximumFontSize)
    }
}
