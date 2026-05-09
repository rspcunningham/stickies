import Combine
import Foundation
import StickiesCore

@MainActor
final class WindowManager {
    private let store: NoteStore
    private var cancellable: AnyCancellable?
    private var controllers: [UUID: NoteWindowController] = [:]

    private(set) var activeNoteID: UUID?

    init(store: NoteStore) {
        self.store = store
    }

    func start() {
        syncWindows(with: store.notes)
        cancellable = store.notesPublisher.sink { [weak self] notes in
            self?.syncWindows(with: notes)
        }
    }

    func orderAllFront() {
        for controller in controllers.values {
            controller.orderFront()
        }
    }

    private func syncWindows(with notes: [StickyNote]) {
        let noteIDs = Set(notes.map(\.id))

        for id in controllers.keys where !noteIDs.contains(id) {
            controllers[id]?.closeFromStore()
            controllers[id] = nil
        }

        for note in notes {
            if let controller = controllers[note.id] {
                controller.update(note: note)
            } else {
                let controller = NoteWindowController(
                    note: note,
                    store: store
                ) { [weak self] noteID in
                    self?.activeNoteID = noteID
                }
                controllers[note.id] = controller
                controller.show()
            }
        }

        if let activeNoteID, !noteIDs.contains(activeNoteID) {
            self.activeNoteID = notes.last?.id
        }
    }
}
