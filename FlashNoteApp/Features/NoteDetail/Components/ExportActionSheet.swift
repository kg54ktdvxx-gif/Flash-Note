import SwiftUI
import FlashNoteCore

struct ExportActionSheet: View {
    let note: Note
    @Binding var isPresented: Bool
    @State private var exportURL: URL?
    @State private var showShareSheet = false
    @State private var exportError: String?

    private let exportService = DefaultExportService()

    var body: some View {
        NavigationStack {
            List {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    Button {
                        exportNote(format: format)
                    } label: {
                        Label(format.displayName, systemImage: iconForFormat(format))
                    }
                }

                if !integrations.isEmpty {
                    Section("Integrations") {
                        ForEach(integrations, id: \.label) { integration in
                            Button {
                                integration.action()
                            } label: {
                                Label(integration.label, systemImage: integration.icon)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { isPresented = false }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let exportURL {
                    ShareLink(item: exportURL)
                }
            }
            .alert("Export Error", isPresented: .init(
                get: { exportError != nil },
                set: { if !$0 { exportError = nil } }
            )) {
                Button("OK") { exportError = nil }
            } message: {
                if let exportError { Text(exportError) }
            }
            .onDisappear {
                if let exportURL {
                    try? FileManager.default.removeItem(at: exportURL)
                }
            }
        }
    }

    private struct Integration {
        let label: String
        let icon: String
        let action: () -> Void
    }

    private var integrations: [Integration] {
        var result: [Integration] = []
        if UIApplication.shared.canOpenURL(URL(string: "x-apple-reminderkit://")!) {
            result.append(Integration(label: "Add to Reminders", icon: "checklist", action: openInReminders))
        }
        if UIApplication.shared.canOpenURL(URL(string: "things:///")!) {
            result.append(Integration(label: "Send to Things", icon: "square.and.arrow.up", action: openInThings))
        }
        if UIApplication.shared.canOpenURL(URL(string: "obsidian://")!) {
            result.append(Integration(label: "Send to Obsidian", icon: "doc.text", action: openInObsidian))
        }
        return result
    }

    private func iconForFormat(_ format: ExportFormat) -> String {
        switch format {
        case .markdown: "doc.richtext"
        case .plainText: "doc.plaintext"
        case .json: "curlybraces"
        }
    }

    private func exportNote(format: ExportFormat) {
        // Clean up any previous export temp file
        if let previousURL = exportURL {
            try? FileManager.default.removeItem(at: previousURL)
        }

        do {
            exportURL = try exportService.exportToFile(notes: [note], format: format)
            showShareSheet = true
        } catch {
            FNLog.export.error("Export failed: \(error)")
            exportError = "Export failed. Please try again."
        }
    }

    private func openInReminders() {
        var components = URLComponents()
        components.scheme = "x-apple-reminderkit"
        components.host = "REMCDReminder"
        components.path = "/create"
        components.queryItems = [URLQueryItem(name: "title", value: note.text)]
        guard let url = components.url else { return }
        UIApplication.shared.open(url)
    }

    private func openInThings() {
        var components = URLComponents()
        components.scheme = "things"
        components.path = "///add"
        components.queryItems = [URLQueryItem(name: "title", value: note.text)]
        guard let url = components.url else { return }
        UIApplication.shared.open(url)
    }

    private func openInObsidian() {
        var components = URLComponents()
        components.scheme = "obsidian"
        components.host = "new"
        components.queryItems = [URLQueryItem(name: "content", value: note.text)]
        guard let url = components.url else { return }
        UIApplication.shared.open(url)
    }
}
