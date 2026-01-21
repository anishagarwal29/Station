import SwiftUI

struct UpcomingItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var description: String
    var dueDate: Date
    var category: UpcomingCategory
    var isUrgent: Bool
    var includeTime: Bool
    
    init(id: UUID = UUID(), title: String, description: String = "", dueDate: Date, category: UpcomingCategory, isUrgent: Bool, includeTime: Bool = true) {
        self.id = id
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.category = category
        self.isUrgent = isUrgent
        self.includeTime = includeTime
    }
    
    enum UpcomingCategory: String, Codable, CaseIterable, Identifiable {
        case homework = "HW"
        case test = "Test"
        case event = "Event"
        case announcement = "Announcement"
        
        var id: String { self.rawValue }
        
        var color: Color {
            switch self {
            case .homework: return Color.blue
            case .test: return Color.red
            case .event: return Color.green
            case .announcement: return Color.orange
            }
        }
        
        var icon: String {
            switch self {
            case .homework: return "pencil.and.outline"
            case .test: return "doc.text.fill"
            case .event: return "calendar"
            case .announcement: return "megaphone.fill"
            }
        }
    }
}
