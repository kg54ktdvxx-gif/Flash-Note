import SwiftUI
import SwiftData
import FlashNoteCore

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SettingsViewModel()
    @State private var showExportSheet = false
    @State private var exportURL: URL?
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Enable Resurfacing", isOn: $viewModel.resurfacingEnabled)

                    if viewModel.resurfacingEnabled {
                        Stepper(
                            "Max daily: \(viewModel.maxDailyNotifications)",
                            value: $viewModel.maxDailyNotifications,
                            in: 1...10
                        )

                        Toggle("Quiet Hours (10pm\u{2013}8am)", isOn: $viewModel.quietHoursEnabled)
                    }
                } header: {
                    sectionHeader("RESURFACING")
                }

                Section {
                    Toggle("Daily Review Reminder", isOn: $viewModel.dailyReflectionEnabled)
                    Toggle("Shake to Capture", isOn: $viewModel.shakeEnabled)
                } header: {
                    sectionHeader("CAPTURE")
                }

                Section {
                    statRow("Total", value: "\(viewModel.noteCount)")
                    statRow("Active", value: "\(viewModel.activeNoteCount)")
                    statRow("Archived", value: "\(viewModel.archivedNoteCount)")
                } header: {
                    sectionHeader("STATISTICS")
                }

                Section {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Button {
                            exportURL = viewModel.exportAll(format: format, context: modelContext)
                            if exportURL != nil {
                                showExportSheet = true
                            }
                        } label: {
                            Text("Export as \(format.displayName)")
                                .font(AppTypography.body)
                                .foregroundStyle(AppColors.textPrimary)
                        }
                    }
                } header: {
                    sectionHeader("EXPORT")
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Text("Delete All Archived Notes")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.accent)
                    }
                } header: {
                    sectionHeader("DATA")
                }

                Section {
                    statRow("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    statRow("Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                } header: {
                    sectionHeader("ABOUT")
                } footer: {
                    Text("Made with ❤️ + 🤖 in 🇸🇬")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationTitle("Settings")
            .onAppear {
                viewModel.loadStats(context: modelContext)
            }
            .sheet(isPresented: $showExportSheet) {
                if let exportURL {
                    ShareLink(item: exportURL)
                }
            }
            .alert("Delete Archived Notes?", isPresented: $showDeleteConfirmation) {
                Button("Delete All", role: .destructive) {
                    viewModel.deleteAllArchived(context: modelContext)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete \(viewModel.archivedNoteCount) archived notes.")
            }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.captionSmall)
            .tracking(2)
            .foregroundStyle(AppColors.textTertiary)
    }

    private func statRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
            Text(value)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
    }
}
