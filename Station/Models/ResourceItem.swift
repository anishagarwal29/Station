import SwiftUI

struct ResourceItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var urlString: String
    var tags: [String]
    var iconName: String
    
    init(id: UUID = UUID(), title: String, urlString: String, tags: [String], iconName: String) {
        self.id = id
        self.title = title
        self.urlString = urlString
        self.tags = tags
        self.iconName = iconName
    }
    
    // Helper to get URL safe
    var url: URL? {
        // If user forgets https://, perform smart fix or just try URL(string:)
        let cleaned = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.lowercased().hasPrefix("http") {
             return URL(string: cleaned)
        } else {
             return URL(string: "https://" + cleaned)
        }
    }
}
