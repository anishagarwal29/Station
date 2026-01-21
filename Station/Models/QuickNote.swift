import Foundation

struct QuickNote: Codable, Identifiable {
    let id: UUID
    var content: String
    var lastUpdated: Date
}
