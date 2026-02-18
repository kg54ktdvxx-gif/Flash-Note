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
    ) private var allNotes: [Note]

    /// Limit notes loaded into the section builder to cap memory usage.
    private var notes: [Note] {
        Array(allNotes.prefix(200))
    }

    @State private var viewModel = InboxViewModel()
    @State private var selectedNote: Note?
    @State private var showSearch = false
    @FocusState private var searchFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Editorial inline header — search + triage
                inboxHeader

                EditorialRule()

                // Inline search field (toggled)
                if showSearch {
                    searchField
                    EditorialRule()
                }

                // Content
                if viewModel.isSearchActive && displayedNotes.isEmpty {
                    Spacer()
                    Text("No results for \"\(viewModel.searchText)\"")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textTertiary)
                    Spacer()
                } else if notes.isEmpty && !viewModel.isSearchActive {
                    EmptyInboxView()
                } else {
                    notesList
                }
            }
            .background(AppColors.background)
            .toolbar(.hidden, for: .navigationBar)
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

    // MARK: - Inline Header

    private var inboxHeader: some View {
        HStack {
            // Search toggle
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    showSearch.toggle()
                    if showSearch {
                        searchFocused = true
                    } else {
                        viewModel.searchText = ""
                        searchFocused = false
                    }
                }
            } label: {
                Image(systemName: showSearch ? "xmark" : "magnifyingglass")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(showSearch ? AppColors.textSecondary : AppColors.textTertiary)
            }
            .accessibilityLabel(showSearch ? "Close search" : "Search notes")

            Spacer()

            // Triage link
            NavigationLink {
                TriageView()
            } label: {
                Text("TRIAGE")
                    .font(AppTypography.captionSmall)
                    .tracking(1)
                    .foregroundStyle(AppColors.accent)
            }
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.vertical, 8)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(AppColors.textTertiary)

            TextField("Search notes...", text: $viewModel.searchText)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
                .focused($searchFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onChange(of: viewModel.searchText) {
                    viewModel.search(in: modelContext)
                }
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Notes List

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
