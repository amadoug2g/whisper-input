import Foundation
import AVFoundation

enum AudioRecorderError: LocalizedError {
    case permissionDenied
    case alreadyRecording
    case setupFailed(Error)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone access denied. Enable it in System Settings > Privacy & Security > Microphone."
        case .alreadyRecording:
            return "A recording is already in progress."
        case .setupFailed(let e):
            return "Audio setup failed: \(e.localizedDescription)"
        }
    }
}

class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    private var recorder: AVAudioRecorder?
    private var outputURL: URL?
    private var levelTimer: Timer?

    /// Called periodically with a normalized audio level in [0, 1].
    var onLevelUpdate: ((Float) -> Void)?

    // MARK: - Permissions

    static func requestPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio, completionHandler: completion)
        default:
            completion(false)
        }
    }

    // MARK: - Recording

    func startRecording() throws {
        guard AVCaptureDevice.authorizationStatus(for: .audio) == .authorized else {
            throw AudioRecorderError.permissionDenied
        }
        guard recorder == nil else {
            throw AudioRecorderError.alreadyRecording
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16_000,   // Whisper performs best at 16 kHz
            AVNumberOfChannelsKey: 1,  // Mono
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        let rec = try AVAudioRecorder(url: url, settings: settings)
        rec.delegate = self
        rec.isMeteringEnabled = true
        rec.record()

        recorder = rec
        outputURL = url

        // Poll metering at ~20 fps
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self, let rec = self.recorder, rec.isRecording else { return }
            rec.updateMeters()
            // averagePower is in dB, typically –60 to 0 for speech.
            // Normalize to [0, 1] using a –60 dB floor.
            let dB = rec.averagePower(forChannel: 0)
            let normalized = Float(max(0.0, (dB + 60.0) / 60.0))
            self.onLevelUpdate?(normalized)
        }
    }

    func stopRecording(completion: @escaping (URL?) -> Void) {
        levelTimer?.invalidate()
        levelTimer = nil
        onLevelUpdate?(0)

        recorder?.stop()
        recorder = nil

        completion(outputURL)
        outputURL = nil
    }

    // MARK: - AVAudioRecorderDelegate

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        // Surface encoding errors silently — the stop callback will return nil.
        levelTimer?.invalidate()
        levelTimer = nil
        self.recorder = nil
    }
}
