import StickiesCore
import SwiftUI

@MainActor
struct NoteEditorView: View {
    let noteID: UUID
    @ObservedObject var store: NoteStore

    var body: some View {
        if let note = store.note(id: noteID) {
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: 28)
                    .contentShape(Rectangle())

                TextEditor(text: textBinding(for: note.id))
                    .font(.system(size: 15))
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            }
            .background(note.color.swiftUIColor)
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

    private func textBinding(for id: UUID) -> Binding<String> {
        Binding {
            store.note(id: id)?.text ?? ""
        } set: { newValue in
            store.updateText(id: id, text: newValue)
        }
    }
}

