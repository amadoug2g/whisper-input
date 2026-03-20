import Foundation

enum WhisperError: LocalizedError {
    case missingAPIKey
    case httpError(Int, String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "OpenAI API key is not set. Go to Settings to add it."
        case .httpError(let code, let msg): return "API error \(code): \(msg)"
        case .decodingError: return "Could not parse the transcription response."
        }
    }
}

class WhisperService {
    private let endpoint = URL(string: "https://api.openai.com/v1/audio/transcriptions")!

    /// Transcribes an audio file using the OpenAI Whisper API.
    /// - Parameters:
    ///   - audioURL: Path to the recorded audio file (m4a/wav/mp3).
    ///   - apiKey: OpenAI secret key.
    ///   - language: BCP-47 language code (e.g. "en", "fr"). Pass `nil` for auto-detect.
    func transcribe(audioURL: URL, apiKey: String, language: String?) async throws -> String {
        guard !apiKey.isEmpty else { throw WhisperError.missingAPIKey }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let audioData = try Data(contentsOf: audioURL)
        var body = Data()

        // model field
        body.appendFormField(name: "model", value: "whisper-1", boundary: boundary)
        // response_format
        body.appendFormField(name: "response_format", value: "text", boundary: boundary)
        // language (optional)
        if let lang = language {
            body.appendFormField(name: "language", value: lang, boundary: boundary)
        }
        // audio file
        body.appendFileField(
            name: "file",
            filename: audioURL.lastPathComponent,
            mimeType: "audio/m4a",
            data: audioData,
            boundary: boundary
        )
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw WhisperError.httpError(http.statusCode, message)
        }

        guard let text = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw WhisperError.decodingError
        }
        return text
    }
}

// MARK: - Multipart helpers

private extension Data {
    mutating func appendFormField(name: String, value: String, boundary: String) {
        let field = "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(name)\"\r\n\r\n\(value)\r\n"
        append(field.data(using: .utf8)!)
    }

    mutating func appendFileField(name: String, filename: String, mimeType: String, data: Data, boundary: String) {
        let header = "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\nContent-Type: \(mimeType)\r\n\r\n"
        append(header.data(using: .utf8)!)
        append(data)
        append("\r\n".data(using: .utf8)!)
    }
}
