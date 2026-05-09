import Foundation

public final class NoteDiskStore: @unchecked Sendable {
    public let directory: URL
    private let fileManager: FileManager

    public init(directory: URL, fileManager: FileManager = .default) {
        self.directory = directory
        self.fileManager = fileManager
    }

    public static var defaultDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(StickiesCore.storageDirectoryName, isDirectory: true)
            .appendingPathComponent(StickiesCore.notesDirectoryName, isDirectory: true)
    }

    public func ensureDirectory() throws {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    public func loadNotes() throws -> [StickyNote] {
        try ensureDirectory()

        let files = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )
        .filter { $0.pathExtension.lowercased() == "md" }

        return try files.map { url in
            let data = try Data(contentsOf: url)
            return try NoteFileCodec.decode(data: data, fallbackID: UUID(uuidString: url.deletingPathExtension().lastPathComponent))
        }
        .sorted { lhs, rhs in
            if lhs.createdAt == rhs.createdAt {
                return lhs.id.uuidString < rhs.id.uuidString
            }

            return lhs.createdAt < rhs.createdAt
        }
    }

    public func save(_ note: StickyNote) throws {
        try ensureDirectory()
        let data = try NoteFileCodec.encode(note)
        try data.write(to: url(for: note), options: [.atomic])
    }

    public func delete(_ note: StickyNote) throws {
        try delete(id: note.id)
    }

    public func delete(id: UUID) throws {
        let noteURL = url(for: id)
        guard fileManager.fileExists(atPath: noteURL.path) else {
            return
        }

        try fileManager.removeItem(at: noteURL)
    }

    public func url(for note: StickyNote) -> URL {
        url(for: note.id)
    }

    public func url(for id: UUID) -> URL {
        directory.appendingPathComponent("\(id.uuidString.lowercased()).md", isDirectory: false)
    }
}

