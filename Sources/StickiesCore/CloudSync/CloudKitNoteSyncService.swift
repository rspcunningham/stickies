import CloudKit
import Foundation

@MainActor
final class CloudKitNoteSyncService {
    static let defaultContainerIdentifier = "iCloud.dev.rspcunningham.stickies"

    private enum Field {
        static let text = "text"
        static let color = "color"
        static let frameX = "frameX"
        static let frameY = "frameY"
        static let frameWidth = "frameWidth"
        static let frameHeight = "frameHeight"
        static let floatsAboveWindows = "floatsAboveWindows"
        static let createdAt = "createdAt"
        static let updatedAt = "updatedAt"
    }

    private let container: CKContainer
    private let database: CKDatabase
    private let zoneID = CKRecordZone.ID(zoneName: "Stickies", ownerName: CKCurrentUserDefaultName)
    private let recordType = "StickyNote"
    private let subscriptionID = "stickies-note-zone"
    private var isPrepared = false

    init(containerIdentifier: String = CloudKitNoteSyncService.defaultContainerIdentifier) {
        container = CKContainer(identifier: containerIdentifier)
        database = container.privateCloudDatabase
    }

    func prepareIfNeeded() async throws {
        guard !isPrepared else {
            return
        }

        let accountStatus = try await container.accountStatus()
        guard accountStatus == .available else {
            throw CloudSyncError.accountUnavailable(accountStatus)
        }

        let zone = CKRecordZone(zoneID: zoneID)
        _ = try await database.modifyRecordZones(saving: [zone], deleting: [])
        try await ensureSubscription()
        isPrepared = true
    }

    func fetchNotes() async throws -> [StickyNote] {
        try await prepareIfNeeded()

        var notes: [StickyNote] = []
        var changeToken: CKServerChangeToken?
        var moreComing = true

        while moreComing {
            let response = try await database.recordZoneChanges(
                inZoneWith: zoneID,
                since: changeToken
            )
            try appendNotes(from: response.modificationResultsByID, to: &notes)
            changeToken = response.changeToken
            moreComing = response.moreComing
        }

        return notes.sorted { lhs, rhs in
            if lhs.createdAt == rhs.createdAt {
                return lhs.id.uuidString < rhs.id.uuidString
            }

            return lhs.createdAt < rhs.createdAt
        }
    }

    func save(notes: [StickyNote]) async throws {
        guard !notes.isEmpty else {
            return
        }

        try await prepareIfNeeded()
        let records = notes.map(record(for:))
        let result = try await database.modifyRecords(
            saving: records,
            deleting: [],
            savePolicy: .allKeys,
            atomically: false
        )

        for (_, saveResult) in result.saveResults {
            _ = try saveResult.get()
        }
    }

    func delete(noteIDs: Set<UUID>) async throws {
        guard !noteIDs.isEmpty else {
            return
        }

        try await prepareIfNeeded()
        let recordIDs = noteIDs.map(recordID(for:))
        let result = try await database.modifyRecords(
            saving: [],
            deleting: recordIDs,
            savePolicy: .allKeys,
            atomically: false
        )

        for (_, deleteResult) in result.deleteResults {
            do {
                _ = try deleteResult.get()
            } catch {
                guard error.isCloudKitUnknownItem else {
                    throw error
                }
            }
        }
    }

    private func ensureSubscription() async throws {
        do {
            _ = try await database.subscription(for: subscriptionID)
        } catch {
            guard error.isCloudKitUnknownItem else {
                throw error
            }

            let subscription = CKRecordZoneSubscription(zoneID: zoneID, subscriptionID: subscriptionID)
            let notificationInfo = CKSubscription.NotificationInfo()
            notificationInfo.shouldSendContentAvailable = true
            subscription.notificationInfo = notificationInfo
            _ = try await database.save(subscription)
        }
    }

    private func appendNotes(
        from modificationResultsByID: [CKRecord.ID: Result<CKDatabase.RecordZoneChange.Modification, any Error>],
        to notes: inout [StickyNote]
    ) throws {
        for (_, modificationResult) in modificationResultsByID {
            let record = try modificationResult.get().record
            guard record.recordType == recordType else {
                continue
            }

            notes.append(try note(from: record))
        }
    }

    private func record(for note: StickyNote) -> CKRecord {
        let record = CKRecord(recordType: recordType, recordID: recordID(for: note.id))
        record[Field.text] = note.text
        record[Field.color] = note.color.rawValue
        record[Field.frameX] = note.frame.x
        record[Field.frameY] = note.frame.y
        record[Field.frameWidth] = note.frame.width
        record[Field.frameHeight] = note.frame.height
        record[Field.floatsAboveWindows] = note.floatsAboveWindows ? 1 : 0
        record[Field.createdAt] = note.createdAt
        record[Field.updatedAt] = note.updatedAt
        return record
    }

    private func note(from record: CKRecord) throws -> StickyNote {
        guard let id = UUID(uuidString: record.recordID.recordName),
              let text = record[Field.text] as? String,
              let colorRawValue = record[Field.color] as? String,
              let color = StickyColor(rawValue: colorRawValue),
              let frameX = record[Field.frameX] as? Double,
              let frameY = record[Field.frameY] as? Double,
              let frameWidth = record[Field.frameWidth] as? Double,
              let frameHeight = record[Field.frameHeight] as? Double,
              let createdAt = record[Field.createdAt] as? Date,
              let updatedAt = record[Field.updatedAt] as? Date else {
            throw CloudSyncError.invalidRecord(record.recordID.recordName)
        }

        let floatsAboveWindows = (record[Field.floatsAboveWindows] as? NSNumber)?.boolValue ?? true

        return StickyNote(
            id: id,
            text: text,
            frame: StickyWindowFrame(x: frameX, y: frameY, width: frameWidth, height: frameHeight),
            color: color,
            floatsAboveWindows: floatsAboveWindows,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    private func recordID(for noteID: UUID) -> CKRecord.ID {
        CKRecord.ID(recordName: noteID.uuidString.lowercased(), zoneID: zoneID)
    }
}

enum CloudSyncError: LocalizedError {
    case accountUnavailable(CKAccountStatus)
    case invalidRecord(String)

    var errorDescription: String? {
        switch self {
        case .accountUnavailable(let accountStatus):
            "iCloud is not available for Stickies sync (\(accountStatus.description))."
        case .invalidRecord(let recordName):
            "iCloud returned an unreadable sticky note record: \(recordName)."
        }
    }
}

private extension CKAccountStatus {
    var description: String {
        switch self {
        case .available:
            "available"
        case .couldNotDetermine:
            "could not determine account status"
        case .noAccount:
            "no iCloud account"
        case .restricted:
            "restricted"
        case .temporarilyUnavailable:
            "temporarily unavailable"
        @unknown default:
            "unknown"
        }
    }
}

private extension Error {
    var isCloudKitUnknownItem: Bool {
        guard let ckError = self as? CKError else {
            return false
        }

        return ckError.code == .unknownItem
    }
}
