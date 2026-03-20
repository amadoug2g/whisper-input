import SwiftUI

struct TranscriptionView: View {
    @EnvironmentObject var appState: AppState
    @FocusState private var isEditorFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                statusLabel
                Spacer()
                Button("Cancel") { appState.reset() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial)

            Divider()

            // Transcription editor
            Group {
                if appState.isTranscribing {
                    transcribingPlaceholder
                } else {
                    TextEditor(text: $appState.transcribedText)
                        .focused($isEditorFocused)
                        .font(.body)
                        .padding(12)
                        .frame(minHeight: 100)
                }
            }

            Divider()

            // Footer actions
            HStack {
                if let error = appState.errorMessage {
                    Label(error, systemImage: "exclamationmark.circle")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
                Spacer()
                Button("Paste") {
                    appState.confirmAndPaste()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(appState.transcribedText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial)
        }
        .frame(width: 480)
        .onAppear { isEditorFocused = true }
    }

    // MARK: - Subviews

    private var statusLabel: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var transcribingPlaceholder: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Transcribing…")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var statusText: String {
        switch appState.recordingState {
        case .idle: return "Idle"
        case .recording: return "Recording…"
        case .transcribing: return "Transcribing…"
        case .editing: return "Review & edit"
        }
    }

    private var statusColor: Color {
        switch appState.recordingState {
        case .idle: return .gray
        case .recording: return .red
        case .transcribing: return .orange
        case .editing: return .green
        }
    }
}
