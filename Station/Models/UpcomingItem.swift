/*
 Station > Models > UpcomingItem.swift
 -------------------------------------
 PURPOSE:
 This struct defines a single manual task (e.g. "Math Test").
 
 CONCEPTS:
 - Identifiable: Needed for SwiftUI Lists.
 - Codable: Needed for saving to UserDefaults.
 - Equatable: Needed for comparing items (implicitly used by SwiftUI for diffing).
 */

import SwiftUI

struct UpcomingItem: Identifiable, Codable, Equatable {
    // Unique ID used to track this item even if title changes.
    let id: UUID
    var title: String
    var description: String
    var dueDate: Date
    var category: UpcomingCategory
    var isUrgent: Bool
    var includeTime: Bool // If false, treated as "All Day" for that date
    
    init(id: UUID = UUID(), title: String, description: String = "", dueDate: Date, category: UpcomingCategory, isUrgent: Bool, includeTime: Bool = true) {
        self.id = id
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.category = category
        self.isUrgent = isUrgent
        self.includeTime = includeTime
    }
    
    /*
     ENUM: UpcomingCategory
     ----------------------
     Defines the "Type" of task.
     Using an Enum ensures we only have a fixed set of options (safer than using loose Strings).
     We also attach UI properties (Color, Icon) directly to the data type.
     */
    enum UpcomingCategory: String, Codable, CaseIterable, Identifiable {
        case homework = "HW"
        case test = "Test"
        case event = "Event"
        case announcement = "Announcement"
        
        var id: String { self.rawValue }
        
        // COMPUTED PROPERTY:
        // Returns the Color associated with this category.
        var color: Color {
            switch self {
            case .homework: return Color.blue
            case .test: return Color.red
            case .event: return Color.green
            case .announcement: return Color.orange
            }
        }
        
        // COMPUTED PROPERTY:
        // Returns the SF Symbol string for this category.
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
