import AppKit
import StickiesCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private enum DefaultsKey {
        static let notesFloatAboveOtherWindows = "notesFloatAboveOtherWindows"
    }

    private let noteStore = NoteStore()
    private var windowManager: WindowManager?
    private var floatAboveOtherWindowsItem: NSMenuItem?

    private var notesFloatAboveOtherWindows: Bool {
        get {
            if UserDefaults.standard.object(forKey: DefaultsKey.notesFloatAboveOtherWindows) == nil {
                return true
            }

            return UserDefaults.standard.bool(forKey: DefaultsKey.notesFloatAboveOtherWindows)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: DefaultsKey.notesFloatAboveOtherWindows)
            floatAboveOtherWindowsItem?.state = newValue ? .on : .off
            windowManager?.setNotesFloatAboveOtherWindows(newValue)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMainMenu()

        noteStore.start()
        let windowManager = WindowManager(
            store: noteStore,
            notesFloatAboveOtherWindows: notesFloatAboveOtherWindows
        )
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

    @objc private func closeActiveNote(_ sender: Any?) {
        guard let noteID = windowManager?.activeNoteID ?? noteStore.notes.last?.id else {
            return
        }

        noteStore.deleteNote(id: noteID)
    }

    @objc private func toggleNotesFloatAboveOtherWindows(_ sender: Any?) {
        notesFloatAboveOtherWindows.toggle()
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

        let closeItem = fileMenu.addItem(withTitle: "Close Note", action: #selector(closeActiveNote(_:)), keyEquivalent: "w")
        closeItem.target = self

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
        let floatItem = windowMenu.addItem(
            withTitle: "Float Notes Above Other Windows",
            action: #selector(toggleNotesFloatAboveOtherWindows(_:)),
            keyEquivalent: "f"
        )
        floatItem.keyEquivalentModifierMask = [.command, .option]
        floatItem.target = self
        floatItem.state = notesFloatAboveOtherWindows ? .on : .off
        floatAboveOtherWindowsItem = floatItem

        windowMenu.addItem(.separator())
        windowMenu.addItem(withTitle: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")
        NSApp.windowsMenu = windowMenu

        return windowItem
    }
}
