import Foundation
import Combine


class NotesManager: ObservableObject {
    @Published var notes: [QuickNote] = []
    
    private let storageKey = "station_quick_notes_list"
    
    init() {
        loadNotes()
    }
    
    func addNote(_ content: String) {
        let newNote = QuickNote(id: UUID(), content: content, lastUpdated: Date())
        notes.insert(newNote, at: 0) // Add to top
        saveNotes()
    }
    
    func deleteNote(id: UUID) {
        notes.removeAll { $0.id == id }
        saveNotes()
    }
    
    // For now, completion behaves same as delete (removes from list)
    func completeNote(id: UUID) {
        deleteNote(id: id)
    }
    
    private func saveNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadNotes() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([QuickNote].self, from: data) {
            notes = decoded
        } else {
            // Check for legacy single note
            if let legacyData = UserDefaults.standard.data(forKey: "station_latest_note"),
               let legacyNote = try? JSONDecoder().decode(QuickNote.self, from: legacyData) {
                notes = [legacyNote]
            } else {
                // Default placeholder for fresh install
                notes = [
                    QuickNote(
                        id: UUID(),
                        content: "\"Don't forget to ask Mr. Smith about the extra credit assignment.\"",
                        lastUpdated: Date().addingTimeInterval(-7200)
                    )
                ]
            }
        }
    }
}
