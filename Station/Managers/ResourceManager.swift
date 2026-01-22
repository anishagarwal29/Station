import SwiftUI
import Combine

class ResourceManager: ObservableObject {
    @Published var items: [ResourceItem] = [] {
        didSet {
            saveItems()
        }
    }
    
    private let key = "station_resources_list"
    
    init() {
        loadItems()
    }
    
    func addItem(title: String, urlString: String, tags: [String], iconName: String) {
        let newItem = ResourceItem(title: title, urlString: urlString, tags: tags, iconName: iconName)
        items.append(newItem)
    }
    
    func deleteItem(id: UUID) {
        items.removeAll { $0.id == id }
    }
    
    private func saveItems() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    private func loadItems() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([ResourceItem].self, from: data) {
            items = decoded
        }
    }
}
