/*
 Station > Managers > UpcomingManager.swift
 ------------------------------------------
 PURPOSE:
 This class manages the "Manual" To-Do list (Tests, Homework, etc.) that the user types in.
 It is distinct from Calendar events (which are read-only).
 
 RESPONSIBILITIES:
 1. CRUD (Create, Read, Update, Delete) for UpcomingItems.
 2. Hygiene: Automatically deletes old items after they expire.
 3. Alerts: tracks which alerts the user has dismissed.
 */

import SwiftUI
import Combine

class UpcomingManager: ObservableObject {
    // MAIN DATA: The list of manual tasks.
    @Published var items: [UpcomingItem] = [] {
        didSet {
            // Auto-save whenever the list changes.
            saveItems()
        }
    }
    
    // ALERTS TRACKING:
    // We store a list of IDs (String) for alerts the user has "Cleared" (X button).
    // This ensures that even if we refresh the data, we don't annoy the user with the same alert again.
    // We use `Set` for O(1) fast lookups.
    @Published var clearedAlertIDs: Set<String> = [] {
        didSet {
            saveClearedAlerts()
        }
    }
    
    private let itemsKey = "station_upcoming_items_list"
    private let clearedAlertsKey = "station_cleared_alerts_list"
    
    init() {
        loadItems()
        loadClearedAlerts()
    }
    
    // MARK: - Actions
    
    func addItem(title: String, description: String, dueDate: Date, category: UpcomingItem.UpcomingCategory, isUrgent: Bool, includeTime: Bool) {
        let newItem = UpcomingItem(title: title, description: description, dueDate: dueDate, category: category, isUrgent: isUrgent, includeTime: includeTime)
        items.append(newItem)
        sortAndCleanItems()
    }
    
    func updateItem(_ item: UpcomingItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
            sortAndCleanItems()
        }
    }
    
    func deleteItem(id: UUID) {
        items.removeAll { $0.id == id } // Triggers didSet -> saveItems()
    }
    
    func markAlertsAsCleared(ids: [String]) {
        clearedAlertIDs.formUnion(ids) // specific 'Set' method to add array of items efficiently
    }
    
    func refresh() {
        sortAndCleanItems()
    }
    
    func resetAllManualItems() {
        items = []
        clearedAlertIDs = []
    }
    
    // MARK: - Logic: Hygiene & Sorting
    
    private func sortAndCleanItems() {
        // CLEANUP LOGIC:
        // We remove items that are significantly past due.
        // We keep them for 15 minutes (910 seconds) after the due time so "X mins ago" alerts can still be seen.
        let now = Date()
        let expirationThreshold = now.addingTimeInterval(-910) // 15 minutes + buffer
        
        items.removeAll { inputItem in
             // If item is older than 15 mins ago, delete it forever.
             return inputItem.dueDate < expirationThreshold
        }
        
        // CLEANUP ALERTS:
        // If an item was deleted, we should also forget that we cleared its alert.
        // This keeps the `clearedAlertIDs` file from growing infinitely over years of usage.
        let currentIDs = Set(items.map { $0.id.uuidString })
        // Intersection: Keep only IDs that exist in BOTH 'cleared' and 'current items'.
        clearedAlertIDs = clearedAlertIDs.intersection(currentIDs)
        
        // SORTING:
        // 1. Urgent items always on top.
        // 2. Then sorted by Date (Soonest first).
        items.sort {
            if $0.isUrgent == $1.isUrgent {
                return $0.dueDate < $1.dueDate
            }
            return $0.isUrgent && !$1.isUrgent
        }
    }
    
    // MARK: - Persistence
    
    private func saveItems() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: itemsKey)
        }
    }
    
    private func saveClearedAlerts() {
        // Convert Set<String> to Array for JSON encoding
        let array = Array(clearedAlertIDs)
        if let encoded = try? JSONEncoder().encode(array) {
            UserDefaults.standard.set(encoded, forKey: clearedAlertsKey)
        }
    }
    
    private func loadItems() {
        if let data = UserDefaults.standard.data(forKey: itemsKey),
           let decoded = try? JSONDecoder().decode([UpcomingItem].self, from: data) {
            items = decoded
            sortAndCleanItems()
        }
    }
    
    private func loadClearedAlerts() {
        if let data = UserDefaults.standard.data(forKey: clearedAlertsKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            clearedAlertIDs = Set(decoded)
        }
    }
}
