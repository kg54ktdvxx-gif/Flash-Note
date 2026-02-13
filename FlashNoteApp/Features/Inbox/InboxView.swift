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
            .toolbarBackground(AppColors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .searchable(text: $viewModel.searchText, prompt: "Search...")
            .onChange(of: viewModel.searchText) {
                viewModel.search(in: modelContext)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        TriageView()
                    } label: {
                        Text("TRIAGE")
                            .font(AppTypography.captionSmall)
                            .tracking(1)
                            .foregroundStyle(AppColors.accent)
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
            // Capture streak banner
            if !viewModel.isSearchActive && captureStreak >= 2 {
                HStack(spacing: AppSpacing.xxs) {
                    Text("\(captureStreak)-day streak")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            if viewModel.isSearchActive {
                ForEach(displayedNotes) { note in
                    noteRow(note)
                }
            } else {
                ForEach(sections) { section in
                    Section {
                        ForEach(section.notes) { note in
                            noteRow(note)
                        }
                    } header: {
                        // Editorial section header: uppercase monospace
                        Text(section.title)
                            .font(AppTypography.sectionHeader)
                            .tracking(2)
                            .foregroundStyle(AppColors.textTertiary)
                            .textCase(.uppercase)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable {
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
        .listRowBackground(AppColors.background)
        .listRowSeparatorTint(AppColors.divider)
        .swipeActions(edge: .leading) {
            Button {
                viewModel.togglePin(note, context: modelContext)
            } label: {
                Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin")
            }
            .tint(AppColors.textPrimary)
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
