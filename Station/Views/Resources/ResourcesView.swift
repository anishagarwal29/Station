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
    // @EnvironmentObject: We now get this from StationApp, shared with the Dashboard.
    @EnvironmentObject var resourceManager: ResourceManager
    
    // @State: Local UI variables. Changing these triggers a re-render.
    @State private var searchText = ""
    @State private var selectedTag: String? = nil
    @State private var showingAddSheet = false
    @State private var itemToEdit: ResourceItem? = nil
    @State private var itemToDelete: ResourceItem? = nil
    @State private var showDeleteConfirmation = false
    
    // DEEP LINK: Sheet Logic
    // We can't init the sheet with data directly from here easily without a binding.
    // Instead, we'll use a side-effect. When 'pendingResource' appears, we open the sheet.
    // The Sheet itself will have to read 'pendingResource' from the manager.
    
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
        .sorted { (item1, item2) -> Bool in
            // Sort Rule: Pinned items come first
            if item1.isPinned != item2.isPinned {
                return item1.isPinned
            } else {
                // Secondary Sort: Date Created (Newest First)
                return item1.dateCreated > item2.dateCreated
            }
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
             // Grid Content
             if resourceManager.items.isEmpty {
                 Spacer()
                 StationEmptyState(icon: "folder.badge.plus", message: "Your study hub is empty. Add your first resource to get started!")
                     .padding(32)
                 Spacer()
             } else {
                 ScrollView {
                     LazyVGrid(columns: columns, spacing: 16) {
                         ForEach(filteredItems) { item in
                             ResourceCard(item: item, onOpen: {
                                 // EVENT HANDLER: Opening URLs
                                 // When the "Open" button is clicked:
                                 // 1. We unwrap the safely computed URL (see ResourceItem.swift).
                                 if let url = item.url {
                                     // 2. We ask the macOS Workspace (the OS itself) to open this URL.
                                     // This launches the default browser (Safari, Chrome) or app associated with the link.
                                     NSWorkspace.shared.open(url)
                                 }
                              }, onTogglePin: {
                                  var updated = item
                                  updated.isPinned.toggle()
                                  resourceManager.updateItem(updated)
                              }, onEdit: {
                                  itemToEdit = item
                                  showingAddSheet = true
                              }, onDelete: {
                                  itemToDelete = item
                                  showDeleteConfirmation = true
                              })
                          }
                      }
                      .padding(32)
                      .padding(.bottom, 80) // Space for bottom tab bar
                  }
              }
         }
         .background(Theme.background)
         .sheet(isPresented: $showingAddSheet, onDismiss: { 
             itemToEdit = nil 
         }) {
             AddResourceSheet(manager: resourceManager, isPresented: $showingAddSheet, itemToEdit: itemToEdit)
         }
         .confirmationDialog("Delete Resource?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
             Button("Delete", role: .destructive) {
                 if let item = itemToDelete {
                     resourceManager.deleteItem(id: item.id)
                 }
             }
         } message: {
             Text("Are you sure you want to delete this resource? This cannot be undone.")
         }
    }
}

// Subview for the Card
struct ResourceCard: View {
    let item: ResourceItem
    // Closure: Allows the parent view to define WHAT happens when tapped,
    // while this view handles HOW it looks and detects the tap.
    let onOpen: () -> Void
    let onTogglePin: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovering = false
    @State private var showControls = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
             HStack(alignment: .center, spacing: 12) {
                 // ... (Icon logic)
                 Image(systemName: item.iconName)
                     .font(.system(size: 24))
                     .foregroundColor(Theme.accentBlue)
                     .frame(width: 48, height: 48)
                     .background(Theme.accentBlue.opacity(0.1))
                     .cornerRadius(12)
                 
                 Spacer()
                 
                 // Tags moved to the right
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
        // Absolute Pin Badge - "Pinned to Board" Look
        .overlay(alignment: .topTrailing) {
            if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 14)) // Slightly larger for the "physical" look
                    .foregroundColor(Theme.textSecondary.opacity(0.8))
                    .rotationEffect(.degrees(45))
                    .padding(8)
                    .background(Circle().fill(Theme.background).frame(width: 24, height: 24).shadow(radius: 2))
                    .offset(x: 8, y: -8) // Push it half-out
            }
        }
        // Hover Overlay for Edit/Delete
        .overlay(
            ZStack {
                if showControls {
                    VStack {
                        HStack(spacing: 8) {
                            Button(action: onTogglePin) {
                                Image(systemName: item.isPinned ? "pin.slash.fill" : "pin.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Theme.textPrimary)
                                    .frame(width: 32, height: 32)
                            }
                            .buttonStyle(.plain)
                            .help(item.isPinned ? "Unpin" : "Pin")

                            Button(action: onEdit) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: onDelete) {
                                Image(systemName: "trash")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.red)
                                    .frame(width: 32, height: 32)
                            }
                            .buttonStyle(.plain)
                        }
                        .background(Material.ultraThin)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(8)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        )
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.2)) {
                showControls = hover
            }
        }
    }
}
