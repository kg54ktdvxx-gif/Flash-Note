import SwiftUI

struct ChecklistEditor: View {
    @Binding var text: String
    @State private var items: [ChecklistItem] = []
    @FocusState private var focusedItemID: UUID?

    struct ChecklistItem: Identifiable {
        let id = UUID()
        var content: String = ""
        var isCompleted: Bool = false
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach($items) { $item in
                    checklistRow(item: $item)

                    EditorialRule()
                }

                // Add item button
                Button {
                    addItem()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(AppColors.textTertiary)
                            .frame(width: 18, height: 18)

                        Text("Add item")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.textTertiary)

                        Spacer()
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.vertical, AppSpacing.sm)
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            parseText()
            if items.isEmpty {
                addItem()
            }
        }
        .onChange(of: items.map({ "\($0.isCompleted)|\($0.content)" })) {
            serializeToText()
        }
    }

    private func checklistRow(item: Binding<ChecklistItem>) -> some View {
        HStack(alignment: .top, spacing: 10) {
            // Checkbox
            Button {
                item.wrappedValue.isCompleted.toggle()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(item.wrappedValue.isCompleted ? AppColors.accent : AppColors.border, lineWidth: 1)
                        .frame(width: 18, height: 18)

                    if item.wrappedValue.isCompleted {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(AppColors.accent)
                            .frame(width: 18, height: 18)

                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 3)

            // Text field
            TextField("", text: item.content, axis: .vertical)
                .font(AppTypography.body)
                .foregroundStyle(item.wrappedValue.isCompleted ? AppColors.textTertiary : AppColors.textPrimary)
                .strikethrough(item.wrappedValue.isCompleted)
                .focused($focusedItemID, equals: item.wrappedValue.id)
                .onSubmit {
                    addItemAfter(item.wrappedValue)
                }
                .submitLabel(.next)

            // Delete item
            if items.count > 1 {
                Button {
                    removeItem(item.wrappedValue)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(AppColors.textTertiary)
                }
                .buttonStyle(.plain)
                .padding(.top, 5)
            }
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.vertical, AppSpacing.sm)
    }

    // MARK: - Item Management

    private func addItem() {
        let newItem = ChecklistItem()
        items.append(newItem)
        focusedItemID = newItem.id
    }

    private func addItemAfter(_ item: ChecklistItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        let newItem = ChecklistItem()
        items.insert(newItem, at: index + 1)
        focusedItemID = newItem.id
    }

    private func removeItem(_ item: ChecklistItem) {
        items.removeAll { $0.id == item.id }
        if items.isEmpty {
            addItem()
        }
    }

    // MARK: - Serialization

    private func parseText() {
        guard !text.isEmpty else { return }
        let lines = text.components(separatedBy: "\n")
        items = lines.compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("- [x] ") || trimmed.hasPrefix("- [X] ") {
                var item = ChecklistItem()
                item.content = String(trimmed.dropFirst(6))
                item.isCompleted = true
                return item
            } else if trimmed.hasPrefix("- [ ] ") {
                var item = ChecklistItem()
                item.content = String(trimmed.dropFirst(6))
                return item
            } else if !trimmed.isEmpty {
                var item = ChecklistItem()
                item.content = trimmed
                return item
            }
            return nil
        }
    }

    private func serializeToText() {
        text = items
            .filter { !$0.content.isEmpty || items.count == 1 }
            .map { item in
                let checkbox = item.isCompleted ? "[x]" : "[ ]"
                return "- \(checkbox) \(item.content)"
            }
            .joined(separator: "\n")
    }
}
