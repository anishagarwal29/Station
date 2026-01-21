import SwiftUI
import Combine


class UpcomingManager: ObservableObject {
    @Published var items: [UpcomingItem] = [] {
        didSet {
            saveItems()
        }
    }
    
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
        items.removeAll { $0.id == id }
    }
    
    func markAlertsAsCleared(ids: [String]) {
        clearedAlertIDs.formUnion(ids)
    }
    
    func refresh() {
        sortAndCleanItems()
    }
    
    func resetAllManualItems() {
        items = []
        clearedAlertIDs = []
    }
    
    private func sortAndCleanItems() {
        // Remove items that are past due, with a 15-minute grace period
        // This prevents items added "now" from disappearing immediately        // Remove items that are past due
        // We retain items for 15 minutes after their due time to allow for "X min ago" alerts
        let now = Date()
        let expirationThreshold = now.addingTimeInterval(-910) // 15 minutes + buffer
        
        items.removeAll { inputItem in
             // For all items (with or without time), we use the 15m grace period
             // This supports the Alerts logic requiring items to persist for "X min ago"
             return inputItem.dueDate < expirationThreshold
        }
        
        // Also clean up clearedAlertIDs for items that no longer exist
        // This prevents the set from growing indefinitely
        let currentIDs = Set(items.map { $0.id.uuidString })
        clearedAlertIDs = clearedAlertIDs.intersection(currentIDs)
        
        items.sort {
            if $0.isUrgent == $1.isUrgent {
                return $0.dueDate < $1.dueDate
            }
            return $0.isUrgent && !$1.isUrgent
        }
        
        // Save after cleanup (since we modified clearedAlertIDs potentially)
        // If this loop causes infinite recursion due to didSet, we might need flag, 
        // but simple assignment might trigger save twice, which is acceptable for now.
    }
    
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

//hello
