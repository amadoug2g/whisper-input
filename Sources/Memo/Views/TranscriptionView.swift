import SwiftUI

// MARK: - Root view

struct TranscriptionView: View {
    @EnvironmentObject var appState: AppState
    @FocusState private var editorFocused: Bool
    @State private var transcribingElapsed: Int = 0
    @State private var transcribingTimer: Timer?
    @State private var isVisible = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isCompact: Bool {
        appState.isRecording || appState.isTranscribing
    }

    var body: some View {
        Group {
            if isCompact {
                compactBody
            } else {
                fullBody
            }
        }
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.95, anchor: .bottom)
        .animation(.easeOut(duration: 0.15), value: appState.recordingState)
        .onAppear {
            withAnimation(.easeOut(duration: 0.12)) { isVisible = true }
        }
        .onChange(of: appState.recordingState) { state in
            if state == .editing { editorFocused = true }
        }
    }

    // MARK: - Compact pill (recording / transcribing)

    private var compactBody: some View {
        HStack(spacing: 6) {
            if appState.isRecording {
                WaveformView(level: appState.audioLevel)
            } else {
                ProgressView()
                    .scaleEffect(0.55)
                    .frame(width: 14, height: 14)
                if transcribingElapsed >= 2 {
                    Text("\(transcribingElapsed)s")
                        .font(.system(size: 10, weight: .medium).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            reduceTransparency
                ? AnyShapeStyle(Color(NSColor.windowBackgroundColor))
                : AnyShapeStyle(.regularMaterial),
            in: Capsule()
        )
        .shadow(color: Color.primary.opacity(0.12), radius: 8, y: 3)
        .onAppear {
            if appState.isTranscribing { startTranscribingTimer() }
        }
        .onDisappear { stopTranscribingTimer() }
        .onChange(of: appState.isTranscribing) { transcribing in
            if transcribing { startTranscribingTimer() }
            else { stopTranscribingTimer() }
        }
    }

    // MARK: - Full panel (editing / error)

    private var fullBody: some View {
        VStack(spacing: 0) {
            if appState.isEditing {
                editingContent
                Divider()
                footer
            } else if case .error(let message) = appState.recordingState {
                errorContent(message)
            }
        }
        .background(
            reduceTransparency
                ? AnyShapeStyle(Color(NSColor.windowBackgroundColor))
                : AnyShapeStyle(.regularMaterial),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .frame(width: 400)
        .shadow(color: Color.primary.opacity(0.15), radius: 16, y: 5)
    }

    // MARK: - Editing

    private var editingContent: some View {
        TextEditor(text: $appState.transcribedText)
            .focused($editorFocused)
            .font(.body)
            .scrollContentBackground(.hidden)
            .padding(10)
            .frame(minHeight: 72, maxHeight: 140)
            .accessibilityLabel("Transcription")
            .accessibilityHint("Edit text before pasting into the active application")
    }

    // MARK: - Error

    private func errorContent(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
                    .imageScale(.small)
                    .accessibilityHidden(true)
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text("Press ⌥ Space to try again")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 6) {
            Spacer()
            Button("Paste") { appState.confirmAndPaste() }
                .accessibilityLabel("Paste")
                .accessibilityHint("Pastes the transcribed text into the previously active application")
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(appState.transcribedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    // MARK: - Timer helpers

    private func startTranscribingTimer() {
        transcribingElapsed = 0
        transcribingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            transcribingElapsed += 1
        }
    }

    private func stopTranscribingTimer() {
        transcribingTimer?.invalidate()
        transcribingTimer = nil
        transcribingElapsed = 0
    }
}

// MARK: - WaveformView

struct WaveformView: View {
    var level: Float

    private let barCount = 5
    @State private var phases: [Double]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(level: Float) {
        self.level = level
        _phases = State(initialValue: (0..<5).map { Double($0) * 0.5 })
    }

    private let timer = Timer.publish(every: 0.07, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(0..<barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.red.opacity(barOpacity(for: i)))
                    .frame(width: 3, height: reduceMotion ? 8 : barHeight(for: i))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.07), value: barHeight(for: i))
            }
        }
        .frame(height: 20)
        .accessibilityHidden(true)
        .onReceive(timer) { _ in
            if !reduceMotion {
                for i in 0..<barCount { phases[i] += 0.3 }
            }
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let base: CGFloat = 3
        let peak: CGFloat = 18
        let envelope = CGFloat(level)
        let wave = CGFloat((sin(phases[index]) + 1) / 2)
        let idleHeight = base + (peak * 0.12) * wave
        return envelope > 0.02
            ? base + (peak - base) * envelope * (0.5 + 0.5 * wave)
            : idleHeight
    }

    private func barOpacity(for index: Int) -> Double {
        let centre = Double(barCount - 1) / 2
        let dist = abs(Double(index) - centre) / centre
        return 0.9 - dist * 0.25
    }
}
