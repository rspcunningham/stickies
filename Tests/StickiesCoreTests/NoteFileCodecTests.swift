import Foundation
import Testing
@testable import StickiesCore

@Test
func noteFileRoundTripPreservesMetadataAndMarkdown() throws {
    let createdAt = try #require(ISO8601DateFormatter().date(from: "2026-05-09T14:00:00Z"))
    let updatedAt = try #require(ISO8601DateFormatter().date(from: "2026-05-09T14:05:00Z"))
    let note = StickyNote(
        id: try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111")),
        text: "# Heading\n\n- one\n- two",
        frame: StickyWindowFrame(x: 12, y: 34, width: 400, height: 260),
        color: .blue,
        createdAt: createdAt,
        updatedAt: updatedAt
    )

    let data = try NoteFileCodec.encode(note)
    let decoded = try NoteFileCodec.decode(data: data)

    #expect(decoded == note)
}

@Test
func plainMarkdownWithoutMetadataUsesFallbackID() throws {
    let id = try #require(UUID(uuidString: "22222222-2222-2222-2222-222222222222"))
    let decoded = try NoteFileCodec.decode(data: Data("plain **markdown**".utf8), fallbackID: id)

    #expect(decoded.id == id)
    #expect(decoded.text == "plain **markdown**")
    #expect(decoded.frame == .default)
    #expect(decoded.color == .yellow)
}

