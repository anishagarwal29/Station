import SwiftUI

struct ResourcesView: View {
    @StateObject private var resourceManager = ResourceManager()
    @State private var searchText = ""
    @State private var selectedTag: String? = nil
    @State private var showingAddSheet = false
    
    // Dynamically derive tags from all items
    var allTags: [String] {
        let tags = Set(resourceManager.items.flatMap { $0.tags })
        return tags.sorted()
    }
    
    var filteredItems: [ResourceItem] {
        resourceManager.items.filter { item in
            let matchesSearch = searchText.isEmpty || item.title.localizedCaseInsensitiveContains(searchText)
            let matchesTag = selectedTag == nil || (selectedTag != nil && item.tags.contains(selectedTag!))
            return matchesSearch && matchesTag
        }
    }
    
    let columns = [
        GridItem(.adaptive(minimum: 180), spacing: 16)
    ]
    
    var body: some View {
        VStack(spacing: 24) {
             // Header & Add Button
             HStack {
                 Text("Resources")
                     .font(.system(size: 28, weight: .bold))
                     .foregroundColor(Theme.textPrimary)
                 
                 Spacer()
                 
                 Button(action: { showingAddSheet = true }) {
                     Image(systemName: "plus")
                         .foregroundColor(.white)
                         .frame(width: 32, height: 32)
                         .background(Theme.accentBlue)
                         .clipShape(Circle())
                 }
                 .buttonStyle(.plain)
             }
             .padding(.horizontal, 32)
             .padding(.top, 32)
             
             // Search & Filters
             VStack(spacing: 16) {
                 // Search Bar
                 HStack {
                     Image(systemName: "magnifyingglass")
                         .foregroundColor(Theme.textSecondary)
                     TextField("Search resources...", text: $searchText)
                         .textFieldStyle(.plain)
                         .foregroundColor(Theme.textPrimary)
                 }
                 .padding(12)
                 .background(Color.white.opacity(0.05))
                 .cornerRadius(12)
                 .overlay(
                     RoundedRectangle(cornerRadius: 12)
                         .stroke(Color.white.opacity(0.1), lineWidth: 1)
                 )
                 .padding(.horizontal, 32)
                 
                 // Filter Chips
                 ScrollView(.horizontal, showsIndicators: false) {
                     HStack(spacing: 8) {
                         FilterChip(
                             title: "All",
                             isSelected: selectedTag == nil,
                             color: Theme.accentBlue,
                             action: { selectedTag = nil }
                         )
                         
                         ForEach(allTags, id: \.self) { tag in
                             FilterChip(
                                 title: tag,
                                 isSelected: selectedTag == tag,
                                 color: Theme.accentBlue,
                                 action: { selectedTag = tag }
                             )
                         }
                     }
                     .padding(.horizontal, 32)
                 }
             }
             
             // Grid Content
             ScrollView {
                 LazyVGrid(columns: columns, spacing: 16) {
                     ForEach(filteredItems) { item in
                         ResourceCard(item: item) {
                             if let url = item.url {
                                 NSWorkspace.shared.open(url)
                             }
                         }
                         .contextMenu {
                             Button("Delete", role: .destructive) {
                                 resourceManager.deleteItem(id: item.id)
                             }
                         }
                     }
                 }
                 .padding(32)
                 .padding(.bottom, 80) // Space for bottom tab bar
             }
        }
        .background(Theme.background)
        .sheet(isPresented: $showingAddSheet) {
            AddResourceSheet(manager: resourceManager, isPresented: $showingAddSheet)
        }
    }
}

// Subview for the Card
struct ResourceCard: View {
    let item: ResourceItem
    let onOpen: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
             HStack(alignment: .top) {
                 Image(systemName: item.iconName)
                     .font(.system(size: 24))
                     .foregroundColor(Theme.accentBlue)
                     .frame(width: 48, height: 48)
                     .background(Theme.accentBlue.opacity(0.1))
                     .cornerRadius(12)
                 
                 Spacer()
                 
                 // Mini Tags
                 HStack(spacing: 4) {
                     ForEach(item.tags.prefix(2), id: \.self) { tag in
                         Text(tag)
                             .font(.system(size: 10, weight: .bold))
                             .padding(.horizontal, 6)
                             .padding(.vertical, 2)
                             .background(Color.white.opacity(0.1))
                             .cornerRadius(4)
                             .foregroundColor(Theme.textSecondary)
                     }
                     if item.tags.count > 2 {
                         Text("+\(item.tags.count - 2)")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textSecondary)
                     }
                 }
             }
             
             Text(item.title)
                 .font(.system(size: 16, weight: .bold))
                 .foregroundColor(Theme.textPrimary)
                 .lineLimit(1)
             
             Button(action: onOpen) {
                 Text("Open")
                     .font(.system(size: 13, weight: .semibold))
                     .frame(maxWidth: .infinity)
                     .padding(.vertical, 8)
                     .background(isHovering ? Theme.accentBlue : Color.white.opacity(0.05))
                     .foregroundColor(isHovering ? .white : Theme.textPrimary)
                     .cornerRadius(8)
             }
             .buttonStyle(.plain)
             .onHover { isHovering = $0 }
        }
        .padding(16)
        .background(Theme.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}
