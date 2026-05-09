import AppKit
import StickiesCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let noteStore = NoteStore()
    private var windowManager: WindowManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMainMenu()

        noteStore.start()
        let windowManager = WindowManager(store: noteStore)
        self.windowManager = windowManager
        windowManager.start()

        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        noteStore.flushPendingSaves()
    }

    @objc private func newNote(_ sender: Any?) {
        noteStore.createNote()
    }

    @objc private func deleteActiveNote(_ sender: Any?) {
        guard let noteID = windowManager?.activeNoteID ?? noteStore.notes.last?.id else {
            return
        }

        noteStore.deleteNote(id: noteID)
    }

    @objc private func showNotesFolder(_ sender: Any?) {
        NSWorkspace.shared.open(noteStore.notesDirectory)
    }

    private func buildMainMenu() {
        let mainMenu = NSMenu()

        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appItem.submenu = appMenu
        appMenu.addItem(withTitle: "About Stickies", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Stickies", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        let fileItem = NSMenuItem()
        mainMenu.addItem(fileItem)
        let fileMenu = NSMenu(title: "File")
        fileItem.submenu = fileMenu

        let newItem = fileMenu.addItem(withTitle: "New Note", action: #selector(newNote(_:)), keyEquivalent: "n")
        newItem.target = self

        let closeItem = fileMenu.addItem(withTitle: "Close Note", action: #selector(deleteActiveNote(_:)), keyEquivalent: "w")
        closeItem.target = self

        let deleteItem = fileMenu.addItem(withTitle: "Delete Note", action: #selector(deleteActiveNote(_:)), keyEquivalent: "\u{8}")
        deleteItem.target = self

        fileMenu.addItem(.separator())
        let folderItem = fileMenu.addItem(withTitle: "Show Notes Folder", action: #selector(showNotesFolder(_:)), keyEquivalent: "")
        folderItem.target = self

        mainMenu.addItem(editMenuItem())
        mainMenu.addItem(windowMenuItem())

        NSApp.mainMenu = mainMenu
    }

    private func editMenuItem() -> NSMenuItem {
        let editItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editItem.submenu = editMenu

        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        return editItem
    }

    private func windowMenuItem() -> NSMenuItem {
        let windowItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowItem.submenu = windowMenu

        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")
        NSApp.windowsMenu = windowMenu

        return windowItem
    }
}
