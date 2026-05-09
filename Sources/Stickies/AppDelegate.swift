import AppKit
import StickiesCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private enum DefaultsKey {
        static let notesFloatAboveOtherWindows = "notesFloatAboveOtherWindows"
    }

    private let noteStore = NoteStore()
    private var windowManager: WindowManager?
    private var statusItem: NSStatusItem?
    private var floatAboveOtherWindowsItems: [NSMenuItem] = []

    private var notesFloatAboveOtherWindows: Bool {
        get {
            if UserDefaults.standard.object(forKey: DefaultsKey.notesFloatAboveOtherWindows) == nil {
                return true
            }

            return UserDefaults.standard.bool(forKey: DefaultsKey.notesFloatAboveOtherWindows)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: DefaultsKey.notesFloatAboveOtherWindows)
            updateFloatMenuItemStates()
            windowManager?.setNotesFloatAboveOtherWindows(newValue)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMainMenu()
        buildStatusItem()

        noteStore.start()
        let windowManager = WindowManager(
            store: noteStore,
            notesFloatAboveOtherWindows: notesFloatAboveOtherWindows
        )
        self.windowManager = windowManager
        windowManager.start()

        bringAllNotesToFront(nil)
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

    @objc private func bringAllNotesToFront(_ sender: Any?) {
        NSApp.activate(ignoringOtherApps: true)
        windowManager?.orderAllFront()
    }

    @objc private func showNotesFolder(_ sender: Any?) {
        NSWorkspace.shared.open(noteStore.notesDirectory)
    }

    private func buildStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "Stickies")
        item.button?.toolTip = "Stickies"
        item.menu = statusMenu()
        statusItem = item
    }

    private func statusMenu() -> NSMenu {
        let menu = NSMenu()

        menu.addItem(newNoteMenuItem())

        menu.addItem(bringNotesForwardMenuItem())

        menu.addItem(closeNoteMenuItem())

        menu.addItem(.separator())

        let floatItem = makeFloatAboveOtherWindowsItem()
        menu.addItem(floatItem)

        menu.addItem(.separator())

        let folderItem = menu.addItem(withTitle: "Show Notes Folder", action: #selector(showNotesFolder(_:)), keyEquivalent: "")
        folderItem.target = self

        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Stickies", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        return menu
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

        fileMenu.addItem(newNoteMenuItem())

        fileMenu.addItem(closeNoteMenuItem())

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
        windowMenu.addItem(makeFloatAboveOtherWindowsItem())

        windowMenu.addItem(.separator())
        windowMenu.addItem(bringNotesForwardMenuItem())
        NSApp.windowsMenu = windowMenu

        return windowItem
    }

    private func newNoteMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: "New Note", action: #selector(newNote(_:)), keyEquivalent: "n")
        item.target = self
        return item
    }

    private func closeNoteMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: "Close Note", action: #selector(closeActiveNote(_:)), keyEquivalent: "w")
        item.target = self
        return item
    }

    private func bringNotesForwardMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: "Bring Notes Forward", action: #selector(bringAllNotesToFront(_:)), keyEquivalent: "b")
        item.keyEquivalentModifierMask = [.command, .option]
        item.target = self
        return item
    }

    private func makeFloatAboveOtherWindowsItem() -> NSMenuItem {
        let item = NSMenuItem(
            title: "Float Above Windows",
            action: #selector(toggleNotesFloatAboveOtherWindows(_:)),
            keyEquivalent: "f"
        )
        item.keyEquivalentModifierMask = [.command, .option]
        item.target = self
        item.state = notesFloatAboveOtherWindows ? .on : .off
        floatAboveOtherWindowsItems.append(item)
        return item
    }

    private func updateFloatMenuItemStates() {
        let state: NSControl.StateValue = notesFloatAboveOtherWindows ? .on : .off
        for item in floatAboveOtherWindowsItems {
            item.state = state
        }
    }
}
