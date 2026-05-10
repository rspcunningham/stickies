import StickiesCore
import SwiftUI

struct NoteDetailView: View {
    let noteID: UUID
    @ObservedObject var store: NoteStore

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if let note = store.note(id: noteID) {
            ZStack(alignment: .topTrailing) {
                TextEditor(text: textBinding(for: note.id))
                    .font(.system(size: 17, design: .monospaced))
                    .foregroundStyle(.primary)
                    .scrollContentBackground(.hidden)
                    .padding(14)
                    .background(note.color.swiftUIColor)
                    .ignoresSafeArea(edges: .bottom)

                pinIndicator(floatsAboveWindows: note.floatsAboveWindows)
                    .padding(.top, 14)
                    .padding(.trailing, 14)
            }
            .navigationTitle("Sticky")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        colorMenu

                        Button(role: .destructive) {
                            store.deleteNote(id: note.id)
                            dismiss()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Note Options")
                }
            }
        } else {
            ContentUnavailableView("Sticky Deleted", systemImage: "trash")
        }
    }

    private var colorMenu: some View {
        ForEach(StickyColor.allCases, id: \.self) { color in
            Button {
                store.updateColor(id: noteID, color: color)
            } label: {
                Label(color.title, systemImage: color == store.note(id: noteID)?.color ? "checkmark.circle.fill" : "circle")
            }
        }
    }

    private func textBinding(for id: UUID) -> Binding<String> {
        Binding {
            store.note(id: id)?.text ?? ""
        } set: { newValue in
            store.updateText(id: id, text: newValue)
        }
    }

    private func pinIndicator(floatsAboveWindows: Bool) -> some View {
        Image(systemName: floatsAboveWindows ? "pin.fill" : "pin")
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(.black.opacity(floatsAboveWindows ? 0.48 : 0.24))
            .frame(width: 17, height: 17)
            .background(.black.opacity(floatsAboveWindows ? 0.10 : 0.055), in: Circle())
            .accessibilityHidden(true)
    }
}
