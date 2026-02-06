import SwiftUI
import SwiftData
import FlashNoteCore

struct InboxView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NavigationRouter.self) private var router
    @Query(
        filter: #Predicate<Note> { $0.statusRaw != "deleted" },
        sort: \Note.createdAt,
        order: .reverse
    ) private var notes: [Note]

    @State private var viewModel = InboxViewModel()
    @State private var selectedNote: Note?

    var body: some View {
        NavigationStack {
            Group {
                if notes.isEmpty && !viewModel.isSearchActive {
                    EmptyInboxView()
                } else {
                    notesList
                }
            }
            .navigationTitle("Inbox")
            .searchable(text: $viewModel.searchText, prompt: "Search notes...")
            .onChange(of: viewModel.searchText) {
                viewModel.search(in: modelContext)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        TriageView()
                    } label: {
                        Image(systemName: "rectangle.stack")
                    }
                }
            }
            .navigationDestination(item: $selectedNote) { note in
                NoteDetailView(note: note)
            }
            .onChange(of: router.selectedNoteID) { _, noteID in
                if let noteID {
                    selectedNote = notes.first(where: { $0.id == noteID })
                    router.selectedNoteID = nil
                }
            }
        }
    }

    private var displayedNotes: [Note] {
        viewModel.isSearchActive ? viewModel.searchResults : notes
    }

    private var notesList: some View {
        List {
            ForEach(displayedNotes) { note in
                Button {
                    selectedNote = note
                } label: {
                    NoteRowView(note: note)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        viewModel.deleteNote(note, context: modelContext)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    Button {
                        viewModel.archiveNote(note, context: modelContext)
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                    .tint(AppColors.archiveGray)
                }
            }
        }
        .listStyle(.plain)
    }
}
