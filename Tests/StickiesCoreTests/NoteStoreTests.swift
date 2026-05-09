import Foundation
import Testing
@testable import StickiesCore

@MainActor
@Test
func noteStoreCreatesDefaultNoteAndAutosavesTextUpdates() async throws {
    let directory = temporaryDirectory()
    defer {
        try? FileManager.default.removeItem(at: directory)
    }

    let diskStore = NoteDiskStore(directory: directory)
    let store = NoteStore(diskStore: diskStore)
    store.start()
    defer {
        store.stop()
    }

    let note = try #require(store.notes.first)
    store.updateText(id: note.id, text: "autosaved markdown")
    store.updateFloatsAboveWindows(id: note.id, floatsAboveWindows: false)

    try await Task.sleep(for: .milliseconds(650))

    let loaded = try diskStore.loadNotes()
    #expect(loaded.first?.text == "autosaved markdown")
    #expect(loaded.first?.floatsAboveWindows == false)
}

@MainActor
@Test
func noteStoreHotReloadsExternalDiskChanges() async throws {
    let directory = temporaryDirectory()
    defer {
        try? FileManager.default.removeItem(at: directory)
    }

    let diskStore = NoteDiskStore(directory: directory)
    let store = NoteStore(diskStore: diskStore)
    store.start()
    defer {
        store.stop()
    }

    var note = try #require(store.notes.first)
    note.text = "changed outside the app"
    note.updatedAt = Date()
    try diskStore.save(note)

    for _ in 0..<12 {
        if store.note(id: note.id)?.text == "changed outside the app" {
            return
        }

        try await Task.sleep(for: .milliseconds(150))
    }

    #expect(store.note(id: note.id)?.text == "changed outside the app")
}

@MainActor
@Test
func noteStoreAppliesRemoteChangesToMemoryAndDisk() throws {
    let directory = temporaryDirectory()
    defer {
        try? FileManager.default.removeItem(at: directory)
    }

    let diskStore = NoteDiskStore(directory: directory)
    let store = NoteStore(diskStore: diskStore)
    store.start()
    defer {
        store.stop()
    }

    let localNote = try #require(store.notes.first)
    let remoteNote = StickyNote(
        id: try #require(UUID(uuidString: "33333333-3333-3333-3333-333333333333")),
        text: "from icloud",
        color: .green
    )

    store.applyRemoteChanges(upserting: [remoteNote], deleting: [localNote.id])

    #expect(store.note(id: localNote.id) == nil)
    #expect(store.note(id: remoteNote.id) == remoteNote)
    #expect(!FileManager.default.fileExists(atPath: diskStore.url(for: localNote).path))
    #expect(FileManager.default.fileExists(atPath: diskStore.url(for: remoteNote).path))
}

private func temporaryDirectory() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("stickies-tests-\(UUID().uuidString)", isDirectory: true)
}
