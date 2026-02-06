import SwiftUI
import FlashNoteCore

struct ExportActionSheet: View {
    let note: Note
    @Binding var isPresented: Bool
    @State private var exportURL: URL?
    @State private var showShareSheet = false

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

                Section("Integrations") {
                    Button {
                        openInReminders()
                    } label: {
                        Label("Add to Reminders", systemImage: "checklist")
                    }

                    Button {
                        openInThings()
                    } label: {
                        Label("Send to Things", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        openInObsidian()
                    } label: {
                        Label("Send to Obsidian", systemImage: "doc.text")
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
        }
    }

    private func iconForFormat(_ format: ExportFormat) -> String {
        switch format {
        case .markdown: "doc.richtext"
        case .plainText: "doc.plaintext"
        case .json: "curlybraces"
        }
    }

    private func exportNote(format: ExportFormat) {
        do {
            exportURL = try exportService.exportToFile(notes: [note], format: format)
            showShareSheet = true
        } catch {
            FNLog.export.error("Export failed: \(error)")
        }
    }

    private func openInReminders() {
        // Uses EventKit — will be fully implemented in Phase 13
        let encoded = note.text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "x-apple-reminderkit://REMCDReminder/create?title=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }

    private func openInThings() {
        let encoded = note.text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "things:///add?title=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }

    private func openInObsidian() {
        let encoded = note.text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "obsidian://new?content=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }
}
