/*
 Station > Managers > ResourceManager.swift
 ------------------------------------------
 PURPOSE:
 This class acts as the "Brain" or "ViewModel" for the Resources feature.
 It is responsible for:
 1. Holding the 'source of truth' array of items.
 2. Providing methods to add/delete items.
 3. Handling data persistence (saving to/loading from UserDefaults) so data survives app restarts.
 */

import SwiftUI
import Combine

class ResourceManager: ObservableObject {
    // @Published: When this array changes (item added/removed), ANY view watching this object
    // (like ResourcesView) will automatically re-render to show the new data.
    @Published var items: [ResourceItem] = [] {
        didSet {
            // OBSERVER PATTERN:
            // Whenever 'items' is modified (added to or deleted from), this block runs automatically.
            // This ensures we never forget to save our changes.
            saveItems()
        }
    }
    
    // The specific "Frequency" or "ID" we use to store this data in the user's standardized storage.
    private let key = "station_resources_list"
    
    init() {
        // Load data immediately when the app starts up.
        loadItems()
    }
    
    // MARK: - user Actions
    
    func addItem(title: String, urlString: String, tags: [String], iconName: String) {
        let newItem = ResourceItem(title: title, urlString: urlString, tags: tags, iconName: iconName)
        items.append(newItem) // Triggers @Published -> didSet -> saveItems()
    }
    
    func deleteItem(id: UUID) {
        items.removeAll { $0.id == id } // Triggers @Published -> didSet -> saveItems()
    }
    
    // MARK: - Persistence Logic (The "Hard Drive")
    
    private func saveItems() {
        // 1. Encoding: Convert our friendly struct Array into raw binary Data (JSON).
        if let encoded = try? JSONEncoder().encode(items) {
            // 2. Storage: Write that data to UserDefaults.
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    private func loadItems() {
        // 1. Retrieval: Try to find data at our key.
        if let data = UserDefaults.standard.data(forKey: key),
           // 2. Decoding: Try to convert that raw data back into our specific [ResourceItem] type.
           let decoded = try? JSONDecoder().decode([ResourceItem].self, from: data) {
            items = decoded
        }
    }
}
