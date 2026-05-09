import Combine
import Foundation

@MainActor
public final class NoteStore: ObservableObject {
    @Published public private(set) var notes: [StickyNote] = []
    @Published public private(set) var lastError: String?

    public var notesPublisher: Published<[StickyNote]>.Publisher {
        $notes
    }

    public let notesDirectory: URL

    private let diskStore: NoteDiskStore
    private var saveTasks: [UUID: Task<Void, Never>] = [:]
    private var reloadTimer: Timer?
    private var lastDiskFingerprint: DiskFingerprint?

    public init(diskStore: NoteDiskStore = NoteDiskStore(directory: NoteDiskStore.defaultDirectory)) {
        self.diskStore = diskStore
        notesDirectory = diskStore.directory
    }

    public func start() {
        reloadFromDisk(createNoteIfEmpty: true)
        startReloadTimer()
    }

    public func stop() {
        reloadTimer?.invalidate()
        reloadTimer = nil
        flushPendingSaves()
    }

    public func note(id: UUID) -> StickyNote? {
        notes.first { $0.id == id }
    }

    public func createNote() {
        let offset = Double(notes.count % 7) * 28
        var frame = StickyWindowFrame.default
        frame.x += offset
        frame.y -= offset

        let note = StickyNote(
            text: "",
            frame: frame,
            color: StickyColor.allCases[notes.count % StickyColor.allCases.count]
        )

        notes.append(note)
        saveImmediately(note)
    }

    public func deleteNote(id: UUID) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else {
            return
        }

        let note = notes.remove(at: index)
        saveTasks[id]?.cancel()
        saveTasks[id] = nil

        do {
            try diskStore.delete(note)
            lastDiskFingerprint = try diskFingerprint()
        } catch {
            report(error)
        }
    }

    public func updateText(id: UUID, text: String) {
        guard let index = notes.firstIndex(where: { $0.id == id }),
              notes[index].text != text else {
            return
        }

        notes[index].text = text
        notes[index].updatedAt = Date()
        scheduleSave(notes[index])
    }

    public func updateFrame(id: UUID, frame: StickyWindowFrame) {
        guard let index = notes.firstIndex(where: { $0.id == id }),
              notes[index].frame != frame else {
            return
        }

        notes[index].frame = frame
        notes[index].updatedAt = Date()
        scheduleSave(notes[index])
    }

    public func flushPendingSaves() {
        saveTasks.values.forEach { $0.cancel() }
        saveTasks.removeAll()

        for note in notes {
            saveImmediately(note)
        }
    }

    private func startReloadTimer() {
        reloadTimer?.invalidate()
        reloadTimer = Timer.scheduledTimer(withTimeInterval: 0.30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.reloadIfDiskChanged()
            }
        }
        reloadTimer?.tolerance = 0.10
    }

    private func reloadIfDiskChanged() {
        do {
            let fingerprint = try diskFingerprint()
            guard fingerprint != lastDiskFingerprint else {
                return
            }

            reloadFromDisk(createNoteIfEmpty: false)
        } catch {
            report(error)
        }
    }

    private func reloadFromDisk(createNoteIfEmpty: Bool) {
        do {
            var loadedNotes = try diskStore.loadNotes()

            if createNoteIfEmpty, loadedNotes.isEmpty {
                let firstNote = StickyNote(text: "")
                try diskStore.save(firstNote)
                loadedNotes = [firstNote]
            }

            if loadedNotes != notes {
                notes = loadedNotes
            }

            lastDiskFingerprint = try diskFingerprint()
            lastError = nil
        } catch {
            report(error)
        }
    }

    private func scheduleSave(_ note: StickyNote) {
        saveTasks[note.id]?.cancel()
        saveTasks[note.id] = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else {
                return
            }

            self?.saveImmediately(note)
            self?.saveTasks[note.id] = nil
        }
    }

    private func saveImmediately(_ note: StickyNote) {
        do {
            try diskStore.save(note)
            lastDiskFingerprint = try diskFingerprint()
            lastError = nil
        } catch {
            report(error)
        }
    }

    private func diskFingerprint() throws -> DiskFingerprint {
        try DiskFingerprint(directory: notesDirectory)
    }

    private func report(_ error: Error) {
        lastError = error.localizedDescription
    }
}

private struct DiskFingerprint: Equatable {
    var files: [File]

    init(directory: URL) throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: directory.path) else {
            files = []
            return
        }

        files = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        )
        .filter { $0.pathExtension.lowercased() == "md" }
        .map { url in
            let values = try url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
            return File(
                path: url.path,
                modifiedAt: values.contentModificationDate ?? .distantPast,
                size: values.fileSize ?? 0
            )
        }
        .sorted { $0.path < $1.path }
    }

    struct File: Equatable {
        var path: String
        var modifiedAt: Date
        var size: Int
    }
}

