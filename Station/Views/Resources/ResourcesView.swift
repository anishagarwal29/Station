/*
 Station > Views > Resources > ResourcesView.swift
 -------------------------------------------------
 PURPOSE:
 This is the main screen for the Resources tab. It displays your collection of links in a searchable, filterable grid.
 
 LAYOUT STRATEGY:
 - Vertical Stack (VStack) containing Header -> Search/Filter -> Main Grid.
 - Uses a "Lazy" Grid for performance (only loads views visible on screen).
 */

import SwiftUI

struct ResourcesView: View {
    // @StateObject: We OWN this data object. The view creates it, and it stays alive as long as the view is needed.
    @StateObject private var resourceManager = ResourceManager()
    
    // @State: Local UI variables. Changing these triggers a re-render.
    @State private var searchText = ""
    @State private var selectedTag: String? = nil
    @State private var showingAddSheet = false
    
    // LOGIC: Dynamically Calculate Tags
    // We don't store a list of "all valid tags". Instead, we look at all existing items
    // and extract every unique tag found. This means if you delete the last item with "Math",
    // the "Math" filter chip automatically disappears. Clean and self-maintaining.
    var allTags: [String] {
        let tags = Set(resourceManager.items.flatMap { $0.tags })
        return tags.sorted()
    }
    
    // LOGIC: The Filter Pipeline
    // This is the array the UI actually loops over. It takes the raw full list
    // and applies 1) Search Text check AND 2) Selected Tag check.
    var filteredItems: [ResourceItem] {
        resourceManager.items.filter { item in
            let matchesSearch = searchText.isEmpty || item.title.localizedCaseInsensitiveContains(searchText)
            let matchesTag = selectedTag == nil || (selectedTag != nil && item.tags.contains(selectedTag!))
            return matchesSearch && matchesTag
        }
    }
    
    // GRID CONFIGURATION:
    // .adaptive(minimum: 180): The "Magic" layout.
    // It tells SwiftUI: "Fit as many columns as you can, but never sqeeze a column smaller than 180pt."
    // On a wide iMac, you might get 6 columns. On a small MacBook Air, maybe 3.
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
                 // ... (Search Bar code)
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
                             // EVENT HANDLER: Opening URLs
                             // When the "Open" button is clicked:
                             // 1. We unwrap the safely computed URL (see ResourceItem.swift).
                             if let url = item.url {
                                 // 2. We ask the macOS Workspace (the OS itself) to open this URL.
                                 // This launches the default browser (Safari, Chrome) or app associated with the link.
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
    // Closure: Allows the parent view to define WHAT happens when tapped,
    // while this view handles HOW it looks and detects the tap.
    let onOpen: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
             HStack(alignment: .top) {
                 // ... (Icon logic)
                 Image(systemName: item.iconName)
                     .font(.system(size: 24))
                     .foregroundColor(Theme.accentBlue)
                     .frame(width: 48, height: 48)
                     .background(Theme.accentBlue.opacity(0.1))
                     .cornerRadius(12)
                 
                 Spacer()
                 
                 // UI: Tag Pills logic
                 // We only show the first 2 tags to prevent the card from overflowing.
                 // If there are more, we show a "+X" indicator.
                 HStack(spacing: 4) {
                     ForEach(item.tags.prefix(2), id: \.self) { tag in
                         Text(tag)
                             // ... styling ...
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
