import SwiftUI
import SwiftData
import FlashNoteCore

struct ContentView: View {
    @Environment(NavigationRouter.self) private var router
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Note> { $0.statusRaw != "deleted" }
    ) private var notes: [Note]
    @State private var showSettings = false

    var body: some View {
        @Bindable var router = router

        VStack(spacing: 0) {
            // Editorial top bar
            EditorialTabBar(
                selectedTab: $router.selectedTab,
                noteCount: notes.count,
                onSettingsTap: { showSettings = true }
            )

            EditorialRule(weight: 1, color: AppColors.rule)

            // Content
            Group {
                switch router.selectedTab {
                case .capture:
                    CaptureView()
                case .inbox:
                    InboxView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(AppColors.background)
        .onOpenURL { url in
            router.handle(url: url)
        }
        .onReceive(NotificationCenter.default.publisher(for: .deviceShaken)) { _ in
            router.selectedTab = .capture
            NotificationCenter.default.post(name: .focusCaptureTextField, object: nil)
        }
        .onAppear {
            BufferSyncService.flush(to: modelContext)
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
            }
        }
    }
}

// MARK: - Editorial Tab Bar

struct EditorialTabBar: View {
    @Binding var selectedTab: AppTab
    var noteCount: Int = 0
    var onSettingsTap: () -> Void

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 0) {
            // Settings — minimal icon
            Button(action: onSettingsTap) {
                Image(systemName: "gearshape")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.textTertiary)
            }
            .frame(width: 40)

            Spacer()

            // Tab labels — editorial text with underline
            HStack(spacing: AppSpacing.lg) {
                EditorialTabLabel(
                    title: "Write",
                    isSelected: selectedTab == .capture
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = .capture
                    }
                }

                EditorialTabLabel(
                    title: "Inbox",
                    isSelected: selectedTab == .inbox,
                    badge: noteCount > 0 ? "\(noteCount)" : nil
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = .inbox
                    }
                }
            }

            Spacer()

            // Balance spacer
            Spacer()
                .frame(width: 40)
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.top, AppSpacing.sm)
        .padding(.bottom, AppSpacing.xs)
        .background(AppColors.background)
    }
}

struct EditorialTabLabel: View {
    let title: String
    let isSelected: Bool
    var badge: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text(title)
                        .font(AppTypography.caption)
                        .tracking(1.5)
                        .textCase(.uppercase)
                        .foregroundStyle(isSelected ? AppColors.textPrimary : AppColors.textTertiary)

                    if let badge {
                        Text(badge)
                            .font(AppTypography.captionSmall)
                            .foregroundStyle(AppColors.textOnAccent)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(AppColors.accent, in: RoundedRectangle(cornerRadius: 2))
                    }
                }

                // Underline indicator
                Rectangle()
                    .fill(isSelected ? AppColors.textPrimary : Color.clear)
                    .frame(height: 1.5)
            }
        }
        .buttonStyle(.plain)
    }
}
