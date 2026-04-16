import SwiftUI
import AppKit

struct HistoryView: View {
    @ObservedObject var historyStore: HistoryStore
    @State private var searchText: String = ""

    private var filteredEntries: [TranscriptionEntry] {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return historyStore.entries
        }
        let query = searchText.lowercased()
        return historyStore.entries.filter { $0.text.lowercased().contains(query) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search transcriptions…", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Entry list
            if filteredEntries.isEmpty {
                Spacer()
                Text(historyStore.entries.isEmpty ? "No transcriptions yet." : "No results for "\(searchText)".")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                Spacer()
            } else {
                List(filteredEntries) { entry in
                    HistoryRowView(entry: entry)
                        .listRowInsets(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
                }
                .listStyle(.plain)
            }

            Divider()

            // Footer
            HStack {
                Spacer()
                Button("Clear History") {
                    historyStore.clear()
                }
                .foregroundStyle(.red)
                .disabled(historyStore.entries.isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 440, height: 520)
    }
}

// MARK: - Row

private struct HistoryRowView: View {
    let entry: TranscriptionEntry
    @State private var copied = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Self.dateFormatter.string(from: entry.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(entry.text)
                    .font(.body)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button(copied ? "Copied!" : "Copy") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(entry.text, forType: .string)
                withAnimation { copied = true }
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    withAnimation { copied = false }
                }
            }
            .controlSize(.small)
            .buttonStyle(.bordered)
            .frame(width: 60)
        }
    }
}
