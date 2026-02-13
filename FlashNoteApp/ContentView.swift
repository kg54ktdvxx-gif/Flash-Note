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
            // Top tab bar with settings
            TopTabBar(
                selectedTab: $router.selectedTab,
                noteCount: notes.count,
                onSettingsTap: { showSettings = true }
            )

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

struct TopTabBar: View {
    @Binding var selectedTab: AppTab
    var noteCount: Int = 0
    var onSettingsTap: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Settings button
            Button(action: onSettingsTap) {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .frame(width: 44)

            TopTabButton(
                title: "Capture",
                systemImage: "plus.circle.fill",
                isSelected: selectedTab == .capture
            ) {
                selectedTab = .capture
            }

            TopTabButton(
                title: "Inbox",
                systemImage: "tray.fill",
                isSelected: selectedTab == .inbox,
                badgeCount: noteCount
            ) {
                selectedTab = .inbox
            }

            // Spacer for symmetry
            Color.clear
                .frame(width: 44)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.darkSurface)
    }
}

struct TopTabButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    var badgeCount: Int = 0
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: systemImage)
                Text(title)
                if badgeCount > 0 {
                    Text("\(badgeCount)")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textOnPrimary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppColors.primary, in: Capsule())
                }
            }
            .font(AppTypography.headline)
            .foregroundStyle(isSelected ? AppColors.primary : AppColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppBorderRadius.md)
                    .fill(isSelected ? AppColors.primarySoft : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
