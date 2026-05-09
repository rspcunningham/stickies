import Foundation
import Testing
@testable import StickiesCore

@Test
func diskStoreSavesLoadsAndDeletesNotes() throws {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("stickies-tests-\(UUID().uuidString)", isDirectory: true)
    defer {
        try? FileManager.default.removeItem(at: directory)
    }

    let store = NoteDiskStore(directory: directory)
    let note = StickyNote(text: "persist me")

    try store.save(note)
    #expect(FileManager.default.fileExists(atPath: store.url(for: note).path))

    let loaded = try store.loadNotes()
    #expect(loaded == [note])

    try store.delete(note)
    #expect(!FileManager.default.fileExists(atPath: store.url(for: note).path))
}

