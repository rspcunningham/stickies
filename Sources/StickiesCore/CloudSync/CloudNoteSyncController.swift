import Combine
import Foundation

@MainActor
public final class CloudNoteSyncController {
    private enum DefaultsKey {
        static let knownRemoteNoteIDs = "cloudSyncKnownRemoteNoteIDs"
    }

    private let store: NoteStore
    private let service: CloudKitNoteSyncService
    private var cancellable: AnyCancellable?
    private var pollTimer: Timer?
    private var syncTask: Task<Void, Never>?
    private var knownNotesByID: [UUID: StickyNote] = [:]
    private var pendingChangedNotesByID: [UUID: StickyNote] = [:]
    private var pendingDeletedNoteIDs: Set<UUID> = []
    private var isApplyingRemoteChanges = false

    public init(store: NoteStore) {
        self.store = store
        service = CloudKitNoteSyncService()
    }

    init(store: NoteStore, service: CloudKitNoteSyncService) {
        self.store = store
        self.service = service
    }

    public func start() {
        knownNotesByID = notesByID(store.notes)
        cancellable = store.notesPublisher.sink { [weak self] notes in
            self?.handleLocalNotesChanged(notes)
        }

        syncSoon(reason: "startup", delay: .milliseconds(100))
        startPollTimer()
    }

    public func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
        syncTask?.cancel()
        syncTask = nil
        cancellable = nil
    }

    public func syncNow(reason: String) {
        syncSoon(reason: reason, delay: .zero)
    }

    private func startPollTimer() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.syncSoon(reason: "poll", delay: .zero)
            }
        }
        pollTimer?.tolerance = 2
    }

    private func handleLocalNotesChanged(_ notes: [StickyNote]) {
        let nextNotesByID = notesByID(notes)

        guard !isApplyingRemoteChanges else {
            knownNotesByID = nextNotesByID
            return
        }

        let previousIDs = Set(knownNotesByID.keys)
        let nextIDs = Set(nextNotesByID.keys)
        pendingDeletedNoteIDs.formUnion(previousIDs.subtracting(nextIDs))

        for (id, note) in nextNotesByID where knownNotesByID[id] != note {
            pendingChangedNotesByID[id] = note
            pendingDeletedNoteIDs.remove(id)
        }

        knownNotesByID = nextNotesByID
        syncSoon(reason: "local-change", delay: .milliseconds(700))
    }

    private func syncSoon(reason: String, delay: Duration) {
        syncTask?.cancel()
        syncTask = Task { @MainActor [weak self] in
            if delay > .zero {
                try? await Task.sleep(for: delay)
            }

            guard !Task.isCancelled else {
                return
            }

            await self?.performSync(reason: reason)
        }
    }

    private func performSync(reason: String) async {
        do {
            let remoteNotes = try await service.fetchNotes()
            let remoteNotesByID = notesByID(remoteNotes)
            let localNotesByID = notesByID(store.notes)
            let remoteDeletedIDs = knownRemoteNoteIDs.subtracting(remoteNotesByID.keys)
            let localDeletedIDs = pendingDeletedNoteIDs
            var localNotesToPush = pendingChangedNotesByID
            var remoteNotesToApply: [StickyNote] = []
            var remoteNoteIDsToDeleteLocally: Set<UUID> = []

            for id in remoteDeletedIDs where localNotesByID[id] != nil && !localDeletedIDs.contains(id) {
                remoteNoteIDsToDeleteLocally.insert(id)
            }

            for (id, remoteNote) in remoteNotesByID where !localDeletedIDs.contains(id) {
                guard let localNote = localNotesByID[id] else {
                    remoteNotesToApply.append(remoteNote)
                    continue
                }

                if remoteNote.updatedAt > localNote.updatedAt {
                    remoteNotesToApply.append(remoteNote)
                    localNotesToPush[id] = nil
                } else if localNote.updatedAt > remoteNote.updatedAt {
                    localNotesToPush[id] = localNote
                }
            }

            for (id, localNote) in localNotesByID where remoteNotesByID[id] == nil && !remoteNoteIDsToDeleteLocally.contains(id) {
                localNotesToPush[id] = localNote
            }

            if !remoteNotesToApply.isEmpty || !remoteNoteIDsToDeleteLocally.isEmpty {
                isApplyingRemoteChanges = true
                store.applyRemoteChanges(
                    upserting: remoteNotesToApply,
                    deleting: Array(remoteNoteIDsToDeleteLocally)
                )
                knownNotesByID = notesByID(store.notes)
                isApplyingRemoteChanges = false
            }

            if !localDeletedIDs.isEmpty {
                try await service.delete(noteIDs: localDeletedIDs)
            }

            let notesToPush = Array(localNotesToPush.values)
            if !notesToPush.isEmpty {
                try await service.save(notes: notesToPush)
            }

            pendingDeletedNoteIDs.subtract(localDeletedIDs)
            for note in notesToPush where pendingChangedNotesByID[note.id] == note {
                pendingChangedNotesByID[note.id] = nil
            }

            var nextKnownRemoteIDs = Set(remoteNotesByID.keys)
            nextKnownRemoteIDs.subtract(localDeletedIDs)
            nextKnownRemoteIDs.formUnion(notesToPush.map(\.id))
            knownRemoteNoteIDs = nextKnownRemoteIDs
            store.setLastError(nil)
        } catch {
            store.setLastError(error.localizedDescription)
        }
    }

    private var knownRemoteNoteIDs: Set<UUID> {
        get {
            let rawValues = UserDefaults.standard.stringArray(forKey: DefaultsKey.knownRemoteNoteIDs) ?? []
            return Set(rawValues.compactMap(UUID.init(uuidString:)))
        }
        set {
            let rawValues = newValue
                .map { $0.uuidString.lowercased() }
                .sorted()
            UserDefaults.standard.set(rawValues, forKey: DefaultsKey.knownRemoteNoteIDs)
        }
    }

    private func notesByID(_ notes: [StickyNote]) -> [UUID: StickyNote] {
        Dictionary(uniqueKeysWithValues: notes.map { ($0.id, $0) })
    }
}
