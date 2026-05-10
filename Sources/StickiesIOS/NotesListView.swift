import StickiesCore
import SwiftUI

struct NotesListView: View {
    @ObservedObject var store: NoteStore
    let syncNow: () -> Void

    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(store.notes) { note in
                    NavigationLink(value: note.id) {
                        NoteRow(note: note)
                    }
                    .listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16))
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            store.deleteNote(id: note.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Stickies")
            .navigationDestination(for: UUID.self) { noteID in
                NoteDetailView(noteID: noteID, store: store)
            }
            .overlay {
                if store.notes.isEmpty {
                    ContentUnavailableView("No Stickies", systemImage: "note.text")
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let lastError = store.lastError {
                    Text(lastError)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(.regularMaterial)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        syncNow()
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    .accessibilityLabel("Sync Now")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let note = store.createNote()
                        path.append(note.id)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New Note")
                }
            }
        }
    }
}

private struct NoteRow: View {
    let note: StickyNote

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(note.color.swiftUIColor)
                .frame(width: 10, height: 48)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.body.monospaced())
                    .lineLimit(1)

                Text(preview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)
        }
        .padding(.vertical, 3)
    }

    private var title: String {
        let firstLine = note.text
            .split(whereSeparator: \.isNewline)
            .first
            .map(String.init)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let firstLine, !firstLine.isEmpty else {
            return "Untitled"
        }

        return firstLine
    }

    private var preview: String {
        let trimmed = note.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "Empty note"
        }

        return trimmed
    }
}
