import SwiftUI

/// Displays the transcription history with a search bar and per-entry copy button.
struct HistoryView: View {
    @EnvironmentObject private var appState: AppState
    @State private var searchQuery: String = ""
    @State private var copiedID: UUID?

    private var store: any HistoryStoring { appState.historyStore }

    private var displayedEntries: [TranscriptionEntry] {
        store.search(query: searchQuery)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search history…", text: $searchQuery)
                    .textFieldStyle(.plain)
                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(.regularMaterial)

            Divider()

            if displayedEntries.isEmpty {
                emptyState
            } else {
                entryList
            }

            Divider()

            // Clear history footer
            HStack {
                Spacer()
                Button("Clear History") {
                    store.clear()
                }
                .foregroundStyle(.red)
                .buttonStyle(.plain)
                .padding(.vertical, 8)
                .padding(.trailing, 12)
                .disabled(store.entries.isEmpty)
            }
        }
        .frame(minWidth: 420, minHeight: 320)
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 36))
                .foregroundStyle(.quaternary)
            Text(searchQuery.isEmpty ? "No transcriptions yet" : "No results for \"\(searchQuery)\"")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var entryList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(displayedEntries) { entry in
                    EntryRow(entry: entry, copiedID: $copiedID)
                    Divider().padding(.leading, 12)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - EntryRow

private struct EntryRow: View {
    let entry: TranscriptionEntry
    @Binding var copiedID: UUID?

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    private var wasCopied: Bool { copiedID == entry.id }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.text)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.body)
                Text(Self.dateFormatter.string(from: entry.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Button {
                copyEntry()
            } label: {
                Image(systemName: wasCopied ? "checkmark" : "doc.on.doc")
                    .frame(width: 20, height: 20)
                    .foregroundStyle(wasCopied ? .green : .accentColor)
            }
            .buttonStyle(.plain)
            .help("Copy to clipboard")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private func copyEntry() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(entry.text, forType: .string)
        copiedID = entry.id
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            if copiedID == entry.id { copiedID = nil }
        }
    }
}
