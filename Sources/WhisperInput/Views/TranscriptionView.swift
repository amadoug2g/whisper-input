import SwiftUI

// MARK: - Root view

struct TranscriptionView: View {
    @EnvironmentObject var appState: AppState
    @FocusState private var editorFocused: Bool
    @State private var keyMonitor: Any?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
            if appState.isEditing {
                Divider()
                footer
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .frame(width: 480)
        .shadow(color: .black.opacity(0.25), radius: 20, y: 6)
        .onAppear(perform: installKeyMonitor)
        .onDisappear(perform: removeKeyMonitor)
        .onChange(of: appState.recordingState) { _, state in
            if state == .editing { editorFocused = true }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            statusDot
            Text(headerTitle)
                .font(.system(size: 13, weight: .medium))
            Spacer()
            Button("Cancel") { appState.reset() }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var statusDot: some View {
        Circle()
            .fill(dotColor)
            .frame(width: 8, height: 8)
            .overlay {
                if appState.isRecording {
                    Circle()
                        .fill(dotColor.opacity(0.4))
                        .frame(width: 8, height: 8)
                        .scaleEffect(1.0)
                        .animation(
                            .easeInOut(duration: 0.7).repeatForever(autoreverses: true),
                            value: appState.isRecording
                        )
                }
            }
    }

    private var dotColor: Color {
        switch appState.recordingState {
        case .idle:         return .gray
        case .recording:    return .red
        case .transcribing: return .orange
        case .editing:      return .green
        }
    }

    private var headerTitle: String {
        switch appState.recordingState {
        case .idle:         return "Idle"
        case .recording:    return "Listening…"
        case .transcribing: return "Transcribing…"
        case .editing:      return "Review & edit"
        }
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
        case .idle:
            Color.clear.frame(height: 0)
        }
    }

    private var recordingContent: some View {
        VStack(spacing: 10) {
            WaveformView(level: appState.audioLevel)
            Text(appState.recordingMode == .pushToTalk ? "Release to transcribe" : "Tap ⌥ Space to stop")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var transcribingContent: some View {
        HStack(spacing: 10) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Sending to Whisper API…")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var editingContent: some View {
        TextEditor(text: $appState.transcribedText)
            .focused($editorFocused)
            .font(.system(size: 14))
            .scrollContentBackground(.hidden)
            .padding(10)
            .frame(minHeight: 90, maxHeight: 160)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 8) {
            if let err = appState.errorMessage {
                Label(err, systemImage: "exclamationmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
            Spacer()
            Button("Paste  ⌘↩") { appState.confirmAndPaste() }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(appState.transcribedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Keyboard monitor

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak appState] event in
            guard let appState else { return event }
            // Escape → cancel
            if event.keyCode == 53 {
                appState.reset()
                return nil
            }
            // ⌘Return → paste (mirrors the button's keyboard shortcut for robustness)
            if event.keyCode == 36, event.modifierFlags.contains(.command),
               !appState.transcribedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               appState.isEditing {
                appState.confirmAndPaste()
                return nil
            }
            return event
        }
    }

    private func removeKeyMonitor() {
        if let m = keyMonitor { NSEvent.removeMonitor(m) }
        keyMonitor = nil
    }
}

// MARK: - WaveformView

struct WaveformView: View {
    var level: Float

    private let barCount = 7
    @State private var phases: [Double]

    init(level: Float) {
        self.level = level
        // Stagger initial phases so bars aren't in sync
        _phases = State(initialValue: (0..<7).map { Double($0) * 0.45 })
    }

    private let timer = Timer.publish(every: 0.07, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            ForEach(0..<barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor(for: i))
                    .frame(width: 4, height: barHeight(for: i))
                    .animation(.easeInOut(duration: 0.07), value: barHeight(for: i))
            }
        }
        .frame(height: 44)
        .onReceive(timer) { _ in
            for i in 0..<barCount { phases[i] += 0.25 }
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let base: CGFloat = 3
        let peak: CGFloat = 38
        let envelope = CGFloat(level)
        // Each bar oscillates at a slightly different frequency
        let wave = CGFloat((sin(phases[index]) + 1) / 2) // 0…1
        // Minimum visible height even at silence (for a calm idle look)
        let idleHeight = base + (peak * 0.15) * wave
        return envelope > 0.02
            ? base + (peak - base) * envelope * (0.5 + 0.5 * wave)
            : idleHeight
    }

    private func barColor(for index: Int) -> Color {
        // Centre bars are brighter
        let centre = Double(barCount - 1) / 2
        let dist = abs(Double(index) - centre) / centre  // 0 = centre, 1 = edge
        return Color.red.opacity(1.0 - dist * 0.35)
    }
}
