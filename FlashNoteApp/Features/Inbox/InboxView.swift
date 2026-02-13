import SwiftUI
import SwiftData
import FlashNoteCore

struct InboxView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NavigationRouter.self) private var router
    @Query(
        // NoteStatus.deleted.rawValue — @Query requires a compile-time literal
        filter: #Predicate<Note> { $0.statusRaw != "deleted" },
        sort: \Note.createdAt,
        order: .reverse
    ) private var notes: [Note]

    @State private var viewModel = InboxViewModel()
    @State private var selectedNote: Note?

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.inboxBackground
                    .ignoresSafeArea()

                Group {
                    if viewModel.isSearchActive && displayedNotes.isEmpty {
                        ContentUnavailableView.search(text: viewModel.searchText)
                    } else if notes.isEmpty && !viewModel.isSearchActive {
                        EmptyInboxView()
                    } else {
                        notesList
                    }
                }
            }
            .navigationTitle("Inbox")
            .toolbarBackground(AppColors.darkSurface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
                            .foregroundStyle(AppColors.primary)
                    }
                }
            }
            .navigationDestination(item: $selectedNote) { note in
                NoteDetailView(note: note)
            }
            .onChange(of: router.selectedNoteID) { _, noteID in
                if let noteID {
                    if let note = notes.first(where: { $0.id == noteID }) {
                        selectedNote = note
                    } else {
                        FNLog.capture.warning("Deep link note not found: \(noteID)")
                    }
                    router.selectedNoteID = nil
                }
            }
        }
    }

    private var displayedNotes: [Note] {
        viewModel.isSearchActive ? viewModel.searchResults : notes
    }

    private var sections: [InboxSectionBuilder.Section] {
        InboxSectionBuilder.build(from: notes)
    }

    private var captureStreak: Int {
        CaptureStreakService.currentStreak(in: modelContext)
    }

    private var notesList: some View {
        List {
            // Capture streak banner (only when not searching, streak >= 2)
            if !viewModel.isSearchActive && captureStreak >= 2 {
                HStack(spacing: AppSpacing.xxs) {
                    Text("\(captureStreak) day streak")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            if viewModel.isSearchActive {
                // Flat list for search results
                ForEach(displayedNotes) { note in
                    noteRow(note)
                }
            } else {
                // Time-grouped sections
                ForEach(sections) { section in
                    Section {
                        ForEach(section.notes) { note in
                            noteRow(note)
                        }
                    } header: {
                        Text(section.title)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textTertiary)
                            .textCase(.uppercase)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable {
            // Sync any pending buffer entries and trigger haptic
            BufferSyncService.flush(to: modelContext)
            DependencyContainer.shared.hapticService.lightTap()
        }
    }

    private func noteRow(_ note: Note) -> some View {
        Button {
            selectedNote = note
        } label: {
            NoteRowView(note: note)
        }
        .listRowBackground(AppColors.cardBackground)
        .swipeActions(edge: .leading) {
            Button {
                viewModel.togglePin(note, context: modelContext)
            } label: {
                Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin")
            }
            .tint(AppColors.primary)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                viewModel.archiveNote(note, context: modelContext)
            } label: {
                Label("Archive", systemImage: "archivebox")
            }
            .tint(AppColors.archiveGray)

            Button(role: .destructive) {
                viewModel.deleteNote(note, context: modelContext)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
