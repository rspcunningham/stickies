import Foundation

public enum StickiesCore {
    public static let storageDirectoryName = ".stickies"
    public static let notesDirectoryName = "notes"
}

public struct StickyWindowFrame: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public static let `default` = StickyWindowFrame(x: 180, y: 520, width: 340, height: 300)
}

public enum StickyColor: String, CaseIterable, Codable, Sendable {
    case yellow
    case blue
    case green
    case pink
    case graphite
}

public struct StickyNote: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var text: String
    public var frame: StickyWindowFrame
    public var color: StickyColor
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        text: String = "",
        frame: StickyWindowFrame = .default,
        color: StickyColor = .yellow,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.frame = frame
        self.color = color
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var fileName: String {
        "\(id.uuidString.lowercased()).md"
    }
}

