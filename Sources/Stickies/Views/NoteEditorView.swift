import StickiesCore
import SwiftUI

@MainActor
struct NoteEditorView: View {
    let noteID: UUID
    @ObservedObject var store: NoteStore

    var body: some View {
        if let note = store.note(id: noteID) {
            ZStack(alignment: .topTrailing) {
                PlainTextEditor(text: textBinding(for: note.id))
                    .padding(.leading, 12)
                    .padding(.trailing, 47)
                    .padding(.top, 12)
                    .padding(.bottom, 12)

                HStack(spacing: 5) {
                    Button {
                        store.toggleFloatsAboveWindows(id: note.id)
                    } label: {
                        Image(systemName: note.floatsAboveWindows ? "pin.fill" : "pin")
                            .font(.system(size: 7, weight: .semibold))
                            .foregroundStyle(pinForegroundOpacity(floatsAboveWindows: note.floatsAboveWindows))
                            .frame(width: 13, height: 13)
                            .background(pinBackgroundOpacity(floatsAboveWindows: note.floatsAboveWindows), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .help(note.floatsAboveWindows ? "Stop Floating Note" : "Float Note Above Windows")
                    .onHover { pinButtonHovered = $0 }

                    Button {
                        store.deleteNote(id: note.id)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.black.opacity(closeButtonHovered ? 0.70 : 0.45))
                            .frame(width: 13, height: 13)
                            .background(.black.opacity(closeButtonHovered ? 0.18 : 0.10), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Close Note")
                    .onHover { closeButtonHovered = $0 }
                }
                .padding(.top, 7)
                .padding(.trailing, 8)
            }
            .background(note.color.swiftUIColor)
            .ignoresSafeArea(.container, edges: .top)
            .overlay(alignment: .bottomTrailing) {
                if let lastError = store.lastError {
                    Text(lastError)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .padding(8)
                }
            }
            .frame(minWidth: 220, minHeight: 160)
        } else {
            Color.clear
                .frame(minWidth: 220, minHeight: 160)
        }
    }

    @State private var pinButtonHovered = false
    @State private var closeButtonHovered = false

    private func textBinding(for id: UUID) -> Binding<String> {
        Binding {
            store.note(id: id)?.text ?? ""
        } set: { newValue in
            store.updateText(id: id, text: newValue)
        }
    }

    private func pinForegroundOpacity(floatsAboveWindows: Bool) -> Color {
        if floatsAboveWindows {
            return .black.opacity(pinButtonHovered ? 0.70 : 0.48)
        }

        return .black.opacity(pinButtonHovered ? 0.55 : 0.24)
    }

    private func pinBackgroundOpacity(floatsAboveWindows: Bool) -> Color {
        if floatsAboveWindows {
            return .black.opacity(pinButtonHovered ? 0.18 : 0.10)
        }

        return .black.opacity(pinButtonHovered ? 0.14 : 0.055)
    }
}
