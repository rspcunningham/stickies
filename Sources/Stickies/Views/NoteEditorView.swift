import StickiesCore
import SwiftUI

@MainActor
struct NoteEditorView: View {
    let noteID: UUID
    @ObservedObject var store: NoteStore

    var body: some View {
        if let note = store.note(id: noteID) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: textBinding(for: note.id))
                    .font(.system(size: 15))
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.top, 2)
                    .padding(.bottom, 12)

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
                .padding(.top, 7)
                .padding(.leading, 8)
                .onHover { closeButtonHovered = $0 }
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

    @State private var closeButtonHovered = false

    private func textBinding(for id: UUID) -> Binding<String> {
        Binding {
            store.note(id: id)?.text ?? ""
        } set: { newValue in
            store.updateText(id: id, text: newValue)
        }
    }
}
