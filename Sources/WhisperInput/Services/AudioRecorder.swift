import Foundation
import AVFoundation

enum AudioRecorderError: LocalizedError {
    case permissionDenied
    case setupFailed(Error)

    var errorDescription: String? {
        switch self {
        case .permissionDenied: return "Microphone access denied. Enable it in System Settings > Privacy > Microphone."
        case .setupFailed(let e): return "Audio setup failed: \(e.localizedDescription)"
        }
    }
}

class AudioRecorder {
    private var recorder: AVAudioRecorder?
    private var outputURL: URL?

    func startRecording() throws {
        let permission = AVCaptureDevice.authorizationStatus(for: .audio)
        guard permission == .authorized || permission == .notDetermined else {
            throw AudioRecorderError.permissionDenied
        }

        if permission == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { _ in }
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,       // Whisper works well at 16 kHz
            AVNumberOfChannelsKey: 1,     // Mono
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            recorder = try AVAudioRecorder(url: tempURL, settings: settings)
            recorder?.record()
            outputURL = tempURL
        } catch {
            throw AudioRecorderError.setupFailed(error)
        }
    }

    func stopRecording(completion: @escaping (URL?) -> Void) {
        recorder?.stop()
        completion(outputURL)
        recorder = nil
    }
}
