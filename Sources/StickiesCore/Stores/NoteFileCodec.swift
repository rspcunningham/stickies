import Foundation

public enum NoteFileCodec {
    private static let metadataPrefix = "<!-- stickies:"
    private static let metadataSuffix = "-->"

    public static func encode(_ note: StickyNote) throws -> Data {
        let metadata = NoteFileMetadata(note: note)
        let encoder = JSONEncoder.stickiesEncoder
        let metadataData = try encoder.encode(metadata)
        let metadataJSON = String(decoding: metadataData, as: UTF8.self)
        let fileContents = "\(metadataPrefix) \(metadataJSON) \(metadataSuffix)\n\(note.text)"

        return Data(fileContents.utf8)
    }

    public static func decode(data: Data, fallbackID: UUID? = nil) throws -> StickyNote {
        let source = String(decoding: data, as: UTF8.self)

        guard source.hasPrefix(metadataPrefix),
              let metadataEnd = source.range(of: metadataSuffix) else {
            return StickyNote(id: fallbackID ?? UUID(), text: source)
        }

        let metadataStart = source.index(source.startIndex, offsetBy: metadataPrefix.count)
        let metadataSource = source[metadataStart..<metadataEnd.lowerBound]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let metadataData = Data(metadataSource.utf8)
        let metadata = try JSONDecoder.stickiesDecoder.decode(NoteFileMetadata.self, from: metadataData)

        var bodyStart = metadataEnd.upperBound
        if bodyStart < source.endIndex, source[bodyStart].isNewline {
            bodyStart = source.index(after: bodyStart)
        }

        return StickyNote(
            id: metadata.id,
            text: String(source[bodyStart...]),
            frame: metadata.frame,
            color: metadata.color,
            floatsAboveWindows: metadata.floatsAboveWindows,
            createdAt: metadata.createdAt,
            updatedAt: metadata.updatedAt
        )
    }
}

private struct NoteFileMetadata: Codable {
    var id: UUID
    var frame: StickyWindowFrame
    var color: StickyColor
    var floatsAboveWindows: Bool
    var createdAt: Date
    var updatedAt: Date

    init(note: StickyNote) {
        id = note.id
        frame = note.frame
        color = note.color
        floatsAboveWindows = note.floatsAboveWindows
        createdAt = note.createdAt
        updatedAt = note.updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        frame = try container.decode(StickyWindowFrame.self, forKey: .frame)
        color = try container.decode(StickyColor.self, forKey: .color)
        floatsAboveWindows = try container.decodeIfPresent(Bool.self, forKey: .floatsAboveWindows) ?? true
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

private extension JSONEncoder {
    static var stickiesEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .deferredToDate
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var stickiesDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .deferredToDate
        return decoder
    }
}
