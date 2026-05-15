import Foundation

// MARK: - Protocol

protocol Transcribing: AnyObject {
    func transcribe(audioURL: URL, apiKey: String, language: String?) async throws -> String
}

// MARK: - Errors

enum WhisperError: LocalizedError {
    case missingAPIKey
    case httpError(Int, String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key is not set. Open Settings (menubar icon → Settings…) to add it."
        case .httpError(let code, let body):
            if let data = body.data(using: .utf8),
               let json = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                return "API error \(code): \(json.error.message)"
            }
            return "API error \(code): \(body)"
        case .emptyResponse:
            return "The API returned an empty transcription."
        }
    }
}

private struct OpenAIErrorResponse: Decodable {
    struct ErrorBody: Decodable { let message: String }
    let error: ErrorBody
}

class WhisperService: Transcribing {
    // swiftlint:disable:next force_unwrapping
    private let endpoint = URL(string: "https://api.openai.com/v1/audio/transcriptions")!

    /// Ephemeral session: no disk cache, no persistent credential storage.
    private let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest  = 30
        config.timeoutIntervalForResource = 90
        return URLSession(configuration: config)
    }()

    func transcribe(audioURL: URL, apiKey: String, language: String?) async throws -> String {
        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw WhisperError.missingAPIKey
        }

        let audioData = try Data(contentsOf: audioURL)
        let boundary = "Boundary-\(UUID().uuidString)"

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = buildMultipartBody(
            audioData: audioData,
            filename: audioURL.lastPathComponent,
            language: language,
            boundary: boundary
        )

        let (data, response) = try await session.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw WhisperError.httpError(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }

        let text = (String(data: data, encoding: .utf8) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else { throw WhisperError.emptyResponse }
        return text
    }

    // MARK: - Multipart body

    private func buildMultipartBody(
        audioData: Data,
        filename: String,
        language: String?,
        boundary: String
    ) -> Data {
        var body = Data()

        body.appendField(name: "model", value: "gpt-4o-mini-transcribe", boundary: boundary)
        body.appendField(name: "response_format", value: "text", boundary: boundary)
        if let lang = language, !lang.isEmpty {
            body.appendField(name: "language", value: lang, boundary: boundary)
        }
        body.appendFile(
            name: "file",
            filename: filename,
            mimeType: "audio/m4a",
            data: audioData,
            boundary: boundary
        )
        body.append("--\(boundary)--\r\n")

        return body
    }
}

// MARK: - Data helpers

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) { append(data) }
    }

    mutating func appendField(name: String, value: String, boundary: String) {
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        append("\(value)\r\n")
    }

    mutating func appendFile(name: String, filename: String, mimeType: String, data: Data, boundary: String) {
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        append("Content-Type: \(mimeType)\r\n\r\n")
        append(data)
        append("\r\n")
    }
}
