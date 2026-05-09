import AppKit
import StickiesCore
import SwiftUI

@MainActor
final class NoteWindowController: NSObject, NSWindowDelegate {
    let noteID: UUID

    private weak var store: NoteStore?
    private let panel: StickyPanel
    private var isClosingFromStore = false
    private var activationHandler: (UUID) -> Void

    init(
        note: StickyNote,
        store: NoteStore,
        notesFloatAboveOtherWindows: Bool,
        activationHandler: @escaping (UUID) -> Void
    ) {
        noteID = note.id
        self.store = store
        self.activationHandler = activationHandler

        panel = StickyPanel(
            contentRect: note.frame.nsRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        super.init()

        panel.delegate = self
        panel.contentViewController = NSHostingController(rootView: NoteEditorView(noteID: note.id, store: store))
        configureWindow(for: note, notesFloatAboveOtherWindows: notesFloatAboveOtherWindows)
    }

    func show() {
        panel.makeKeyAndOrderFront(nil)
    }

    func orderFront() {
        panel.orderFront(nil)
    }

    func update(note: StickyNote) {
        panel.backgroundColor = note.color.nsColor

        let currentFrame = StickyWindowFrame(nsRect: panel.frame)
        if currentFrame != note.frame, !panel.inLiveResize {
            panel.setFrame(note.frame.nsRect, display: true)
        }
    }

    func setFloatsAboveOtherWindows(_ floatsAboveOtherWindows: Bool) {
        if floatsAboveOtherWindows {
            panel.level = .floating
            panel.isFloatingPanel = true
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        } else {
            panel.level = .normal
            panel.isFloatingPanel = false
            panel.collectionBehavior = []
        }
    }

    func closeFromStore() {
        isClosingFromStore = true
        panel.close()
        isClosingFromStore = false
    }

    func windowDidBecomeKey(_ notification: Notification) {
        activationHandler(noteID)
    }

    func windowDidMove(_ notification: Notification) {
        persistWindowFrame()
    }

    func windowDidResize(_ notification: Notification) {
        persistWindowFrame()
    }

    func windowWillClose(_ notification: Notification) {
        guard !isClosingFromStore else {
            return
        }

        store?.deleteNote(id: noteID)
    }

    private func configureWindow(for note: StickyNote, notesFloatAboveOtherWindows: Bool) {
        panel.title = "Sticky Note"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.minSize = NSSize(width: 220, height: 160)
        panel.backgroundColor = note.color.nsColor
        setFloatsAboveOtherWindows(notesFloatAboveOtherWindows)
        panel.setFrame(note.frame.nsRect.clampedToVisibleScreen(), display: false)
    }

    private func persistWindowFrame() {
        let frame = StickyWindowFrame(nsRect: panel.frame)
        store?.updateFrame(id: noteID, frame: frame)
    }
}

private extension StickyWindowFrame {
    init(nsRect: NSRect) {
        self.init(
            x: nsRect.origin.x,
            y: nsRect.origin.y,
            width: nsRect.size.width,
            height: nsRect.size.height
        )
    }

    var nsRect: NSRect {
        NSRect(x: x, y: y, width: width, height: height)
    }
}

private extension NSRect {
    func clampedToVisibleScreen() -> NSRect {
        guard let visibleFrame = NSScreen.screens.first(where: { $0.visibleFrame.intersects(self) })?.visibleFrame
            ?? NSScreen.main?.visibleFrame else {
            return self
        }

        var rect = self
        rect.size.width = min(max(rect.size.width, 220), visibleFrame.width)
        rect.size.height = min(max(rect.size.height, 160), visibleFrame.height)

        if rect.maxX > visibleFrame.maxX {
            rect.origin.x = visibleFrame.maxX - rect.width
        }
        if rect.minX < visibleFrame.minX {
            rect.origin.x = visibleFrame.minX
        }
        if rect.maxY > visibleFrame.maxY {
            rect.origin.y = visibleFrame.maxY - rect.height
        }
        if rect.minY < visibleFrame.minY {
            rect.origin.y = visibleFrame.minY
        }

        return rect
    }
}
