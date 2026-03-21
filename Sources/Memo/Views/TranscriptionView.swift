import SwiftUI

// MARK: - Root view

struct TranscriptionView: View {
    @EnvironmentObject var appState: AppState
    @FocusState private var editorFocused: Bool
    @State private var transcribingElapsed: Int = 0
    @State private var transcribingTimer: Timer?
    @State private var isVisible = false
    @State private var dotPulsing = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
                .transition(.opacity)
            if appState.isEditing {
                Divider()
                footer
                    .transition(.opacity)
            }
        }
        .background(
            reduceTransparency
                ? AnyShapeStyle(Color(NSColor.windowBackgroundColor))
                : AnyShapeStyle(.regularMaterial),
            in: RoundedRectangle(cornerRadius: 14)
        )
        .frame(width: 480)
        .shadow(color: Color.primary.opacity(0.15), radius: 20, y: 6)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.97, anchor: .bottom)
        .animation(.easeOut(duration: 0.2), value: appState.recordingState)
        .onAppear {
            withAnimation(.easeOut(duration: 0.18)) { isVisible = true }
        }
        .onChange(of: appState.recordingState) { state in
            if state == .editing { editorFocused = true }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            statusDot
            Text(headerTitle)
                .font(.body.weight(.medium))
            Spacer()
            Button("Cancel") { appState.reset() }
                .buttonStyle(.plain)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var statusDot: some View {
        Circle()
            .fill(dotColor)
            .frame(width: 8, height: 8)
            .overlay {
                if appState.isRecording && !reduceMotion {
                    Circle()
                        .stroke(dotColor.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 8, height: 8)
                        .scaleEffect(dotPulsing ? 2.8 : 1)
                        .opacity(dotPulsing ? 0 : 0.8)
                        .animation(
                            .easeOut(duration: 1.0).repeatForever(autoreverses: false),
                            value: dotPulsing
                        )
                        .onAppear { dotPulsing = true }
                        .onDisappear { dotPulsing = false }
                }
            }
            .accessibilityHidden(true)
    }

    private var dotColor: Color {
        switch appState.recordingState {
        case .idle:         return .gray
        case .recording:    return .red
        case .transcribing: return .orange
        case .editing:      return .green
        case .error:        return .red
        }
    }

    private var headerTitle: String {
        switch appState.recordingState {
        case .idle:         return String(localized: "Idle")
        case .recording:    return String(localized: "Listening…")
        case .transcribing: return String(localized: "Transcribing…")
        case .editing:      return String(localized: "Review & edit")
        case .error(let msg): return errorHeaderTitle(for: msg)
        }
    }

    private func errorHeaderTitle(for message: String) -> String {
        let m = message.lowercased()
        if m.contains("microphone") || m.contains("audio") || m.contains("permission") {
            return String(localized: "Recording error")
        }
        if m.contains("api key") || m.contains("invalid key") || m.contains("key is not set") {
            return String(localized: "API key error")
        }
        if m.contains("api error") || m.contains("transcription") || m.contains("empty") {
            return String(localized: "Transcription error")
        }
        if m.contains("reach") || m.contains("connection") || m.contains("network") {
            return String(localized: "Connection error")
        }
        return String(localized: "Error")
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch appState.recordingState {
        case .recording:
            recordingContent
        case .transcribing:
            transcribingContent
        case .editing:
            editingContent
        case .error(let message):
            errorContent(message)
        case .idle:
            Color.clear.frame(height: 0)
        }
    }

    private var recordingContent: some View {
        VStack(spacing: 10) {
            WaveformView(level: appState.audioLevel)
            Text(appState.recordingMode == .pushToTalk ? "Release to transcribe" : "Tap ⌥ Space to stop")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var transcribingContent: some View {
        HStack(spacing: 10) {
            ProgressView()
                .scaleEffect(0.8)
            Text(transcribingElapsed >= 2
                 ? "Transcribing… \(transcribingElapsed)s"
                 : "Transcribing…")
                .font(.body.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .onAppear {
            transcribingElapsed = 0
            transcribingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                transcribingElapsed += 1
            }
        }
        .onDisappear {
            transcribingTimer?.invalidate()
            transcribingTimer = nil
            transcribingElapsed = 0
        }
    }

    private var editingContent: some View {
        TextEditor(text: $appState.transcribedText)
            .focused($editorFocused)
            .font(.body)
            .scrollContentBackground(.hidden)
            .padding(10)
            .frame(minHeight: 88, maxHeight: 160)
            .accessibilityLabel("Transcription")
            .accessibilityHint("Edit text before pasting into the active application")
    }

    private func errorContent(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
                    .imageScale(.medium)
                    .accessibilityHidden(true)
                Text(message)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text("Press ⌥ Space to try again")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 8) {
            Spacer()
            Button("Paste") { appState.confirmAndPaste() }
                .accessibilityLabel("Paste")
                .accessibilityHint("Pastes the transcribed text into the previously active application")
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(appState.transcribedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - WaveformView

struct WaveformView: View {
    var level: Float

    private let barCount = 7
    @State private var phases: [Double]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(level: Float) {
        self.level = level
        _phases = State(initialValue: (0..<7).map { Double($0) * 0.45 })
    }

    private let timer = Timer.publish(every: 0.07, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            ForEach(0..<barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor(for: i))
                    .frame(width: 4, height: reduceMotion ? 12 : barHeight(for: i))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.07), value: barHeight(for: i))
            }
        }
        .frame(height: 44)
        .accessibilityHidden(true)
        .onReceive(timer) { _ in
            if !reduceMotion {
                for i in 0..<barCount { phases[i] += 0.25 }
            }
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let base: CGFloat = 3
        let peak: CGFloat = 38
        let envelope = CGFloat(level)
        let wave = CGFloat((sin(phases[index]) + 1) / 2)
        let idleHeight = base + (peak * 0.15) * wave
        return envelope > 0.02
            ? base + (peak - base) * envelope * (0.5 + 0.5 * wave)
            : idleHeight
    }

    private func barColor(for index: Int) -> Color {
        let centre = Double(barCount - 1) / 2
        let dist = abs(Double(index) - centre) / centre
        return Color.accentColor.opacity(1.0 - dist * 0.35)
    }
}
