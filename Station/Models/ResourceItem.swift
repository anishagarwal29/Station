/*
 Station > Models > ResourceItem.swift
 -------------------------------------
 PURPOSE:
 This struct defines the fundamental data model for a single "Resource" (e.g., a link to a textbook, exam portal, or folder).
 
 CONCEPTS:
 1. Identifiable: Conforming to this protocol allows SwiftUI to uniquely identify each item in lists (using `id`).
 2. Codable: This is crucial for saving data. It allows this complex struct to be automatically converted (encoded) into JSON data for storage and converted back (decoded) when the app launches.
 3. Equatable: Allows us to compare two items efficiently to see if they are the same.
 */

import SwiftUI

struct ResourceItem: Identifiable, Codable, Equatable {
    // A unique identifier generated automatically. This ensures no two items collide, even if they have the same title.
    let id: UUID
    
    // Core properties of a resource
    // Core properties of a resource
    var title: String
    var urlString: String // The raw text typed by the user
    var tags: [String]    // A list of categories like "Math", "Science"
    var iconName: String  // The SF Symbol name string (e.g. "link", "book")
    var isPinned: Bool    // New: Pinned status for Dashboard
    var dateCreated: Date // New: Timestamp for sorting by newest
    
    init(id: UUID = UUID(), title: String, urlString: String, tags: [String], iconName: String, isPinned: Bool = false, dateCreated: Date = Date()) {
        self.id = id
        self.title = title
        self.urlString = urlString
        self.tags = tags
        self.iconName = iconName
        self.isPinned = isPinned
        self.dateCreated = dateCreated
    }
    
    // COMPUTED PROPERTY: URL Sanitization
    // -----------------------------------
    // This logic takes the raw user input (which might be messy) and converts it into a usable `URL` object.
    // Why computed? We don't store the `URL` object directly because `URL` isn't trivially Codable in the same way,
    // and we want to preserve exactly what the user typed in `urlString`.
    var url: URL? {
        // 1. Clean whitespace from ends
        let cleaned = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 2. Smart prefixing: If user forgot "https://", we add it for them.
        // Without this, opening "google.com" might fail in some contexts as it's treated as a local file path.
        if cleaned.lowercased().hasPrefix("http") {
             return URL(string: cleaned)
        } else {
             return URL(string: "https://" + cleaned)
        }
    }
}
