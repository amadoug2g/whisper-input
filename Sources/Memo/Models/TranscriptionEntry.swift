import Foundation

/// A single entry in the transcription history.
struct TranscriptionEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let date: Date
    let language: String?

    init(id: UUID = UUID(), text: String, date: Date = Date(), language: String? = nil) {
        self.id = id
        self.text = text
        self.date = date
        self.language = language
    }
}
