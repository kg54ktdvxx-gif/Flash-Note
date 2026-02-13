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
                Section("Resurfacing") {
                    Toggle("Enable Resurfacing", isOn: $viewModel.resurfacingEnabled)

                    if viewModel.resurfacingEnabled {
                        Stepper(
                            "Max daily: \(viewModel.maxDailyNotifications)",
                            value: $viewModel.maxDailyNotifications,
                            in: 1...10
                        )

                        Toggle("Quiet Hours (10pm - 8am)", isOn: $viewModel.quietHoursEnabled)
                    }
                }

                Section("Capture") {
                    Toggle("Daily Review Reminder", isOn: $viewModel.dailyReflectionEnabled)
                    Toggle("Shake to Capture", isOn: $viewModel.shakeEnabled)
                }

                Section("Statistics") {
                    LabeledContent("Total Notes", value: "\(viewModel.noteCount)")
                    LabeledContent("Active", value: "\(viewModel.activeNoteCount)")
                    LabeledContent("Archived", value: "\(viewModel.archivedNoteCount)")
                }

                Section("Export") {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Button {
                            exportURL = viewModel.exportAll(format: format, context: modelContext)
                            if exportURL != nil {
                                showExportSheet = true
                            }
                        } label: {
                            Label("Export as \(format.displayName)", systemImage: "square.and.arrow.up")
                        }
                    }
                }

                Section("Data") {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete All Archived Notes", systemImage: "trash")
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    LabeledContent("Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                }
            }
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
}
