import Testing
@testable import StickiesCore

@Test
func storageDirectoryNamesAreStable() {
    #expect(StickiesCore.storageDirectoryName == ".stickies")
    #expect(StickiesCore.notesDirectoryName == "notes")
}

