/*
 Station > Views > Upcoming > UpcomingView.swift
 -----------------------------------------------
 PURPOSE:
 The main list view for all "To-Dos" and "Events".
 
 ARCHITECTURE:
 - Aggregates data from `UpcomingManager` (Manual) and `CalendarManager` (Events).
 - Uses a `UnifiedItem` struct to map both data types into a single list.
 - Supports complex filtering:
   1. Date Filters (Settings > Time Limit)
   2. Category Filters (UI Filter Chips)
 */

import SwiftUI
import EventKit

struct UpcomingView: View {
    @EnvironmentObject var upcomingManager: UpcomingManager
    @EnvironmentObject var calendarManager: CalendarManager
    @ObservedObject var settings = SettingsManager.shared
    
    // UI State for Modal Sheet
    @State private var isShowingAddSheet = false
    @State private var itemToEdit: UpcomingItem?
    
    // Filter State: Initially all categories selected
    @State private var selectedFilters: Set<UpcomingItem.UpcomingCategory> = Set(UpcomingItem.UpcomingCategory.allCases)
    
    // VIEW MODEL: Unified Item
    // Since we display both 'UpcomingItem' and 'CalendarEvent' in the same list, 
    // we create a common struct that both can map to.
    struct UnifiedItem: Identifiable {
        let id: String
        let title: String
        let date: Date
        let description: String
        let category: UpcomingItem.UpcomingCategory? // nil for Calendar
        let isUrgent: Bool
        let includeTime: Bool
        let isCalendar: Bool
        let originalItemId: UUID? // Used to link back to the actual object for editing
    }
    
    // COMPUTED PROPERTY: The Mega List
    // Merges, Filters, and Sorts all items.
    var allItems: [UnifiedItem] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        
        // Calculate cutoff date based on settings ("Next 3 Days")
        var cutoffDate: Date?
        if let days = settings.upcomingTimeLimit.days {
            cutoffDate = calendar.date(byAdding: .day, value: days, to: startOfToday)
        }
        
        var unified: [UnifiedItem] = []
        
        // 1. Process Manual Items
        let relevantManualItems = upcomingManager.items.filter { item in
            // Date filter: Today or Future
            var valid = item.dueDate >= startOfToday
            
            // Limit filter
            if let cutoff = cutoffDate {
                valid = valid && item.dueDate <= cutoff
            }
            
            if valid {
               // Apply Category Filter (via UI Chips)
               return selectedFilters.contains(item.category)
            }
            return false
        }
        
        for item in relevantManualItems {
             unified.append(UnifiedItem(
                id: item.id.uuidString,
                title: item.title,
                date: item.dueDate,
                description: item.description,
                category: item.category,
                isUrgent: item.isUrgent,
                includeTime: item.includeTime,
                isCalendar: false,
                originalItemId: item.id
             ))
        }
        
        // 2. Process Calendar Events (If Enabled in Settings)
        if settings.includeCalendarInUpcoming {
             let relevantEvents = calendarManager.events.filter { event in
                 var valid = event.startDate >= startOfToday
                 if let cutoff = cutoffDate {
                     valid = valid && event.startDate <= cutoff
                 }
                 return valid
             }
             
             for event in relevantEvents {
                 unified.append(UnifiedItem(
                    id: event.id,
                    title: event.title,
                    date: event.startDate,
                    description: event.location ?? "", // Map Location to Description
                    category: nil,
                    isUrgent: false,
                    includeTime: true,
                    isCalendar: true,
                    originalItemId: nil
                 ))
             }
        }
        
        // Final Sort: Chronological, then Urgent
        return unified.sorted { 
            if $0.date != $1.date { return $0.date < $1.date }
            return $0.isUrgent && !$1.isUrgent
        }
    }
    
    // COMPUTED PROPERTY: Group items by Date (Sticky Headers)
    // Returns an array of Tuples: (DateKey, [Items])
    var groups: [(Date, [UnifiedItem])] {
        let grouped = Dictionary(grouping: allItems) { item in
            Calendar.current.startOfDay(for: item.date)
        }
        // Dictionary is unsorted, so we must sort by DateKey
        return grouped.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Section
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Upcoming")
                            .font(.system(size: 32, weight: .bold))
                        Text("Your tasks for the coming weeks")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                    
                    // Add Button
                    Button(action: { isShowingAddSheet = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Theme.accentBlue.opacity(0.8))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                // Horizontal Scrollable Filter Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(UpcomingItem.UpcomingCategory.allCases) { category in
                            FilterChip(
                                title: category.rawValue,
                                isSelected: selectedFilters.contains(category),
                                color: category.color
                            ) {
                                toggleFilter(category)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 40)
            .padding(.bottom, 24)
            
            // Main Content Area
            ScrollView {
                if allItems.isEmpty {
                     // Empty State View
                     VStack(spacing: 16) {
                        Image(systemName: "checklist")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.textSecondary.opacity(0.5))
                        Text("No upcoming tasks")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.textSecondary)
                        
                        if selectedFilters.count != UpcomingItem.UpcomingCategory.allCases.count {
                             Text("Try adjusting your filters")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.textSecondary.opacity(0.7))
                        } else {
                            Button("Add Task") {
                                isShowingAddSheet = true
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Theme.accentBlue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    // Conditional Layout: Grouped vs Flat Loop
                    if settings.groupUpcomingByDate {
                        LazyVStack(alignment: .leading, spacing: 24) {
                            ForEach(groups, id: \.0) { date, items in
                                // Date Section
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(formatGroupDate(date))
                                        .font(.headline)
                                        .foregroundColor(Theme.textSecondary)
                                        .padding(.horizontal, 40)
                                    
                                    ForEach(items) { item in
                                        UnifiedUpcomingItemRow(
                                            item: item,
                                            onEdit: { 
                                                // Link back to original object
                                                if let id = item.originalItemId, let manualItem = upcomingManager.items.first(where: { $0.id == id }) {
                                                    itemToEdit = manualItem
                                                }
                                            },
                                            onDelete: { 
                                                if let id = item.originalItemId {
                                                    upcomingManager.deleteItem(id: id)
                                                }
                                            }
                                        )
                                        .padding(.horizontal, 40)
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 40)
                    } else {
                        // Flat List (Simple Mode)
                        LazyVStack(spacing: 12) {
                            ForEach(allItems) { item in
                                UnifiedUpcomingItemRow(
                                    item: item,
                                    onEdit: { 
                                        if let id = item.originalItemId, let manualItem = upcomingManager.items.first(where: { $0.id == id }) {
                                            itemToEdit = manualItem
                                        }
                                    },
                                    onDelete: { 
                                        if let id = item.originalItemId {
                                            upcomingManager.deleteItem(id: id)
                                        }
                                    }
                                )
                                .padding(.horizontal, 40)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .onAppear {
                upcomingManager.refresh()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .sheet(isPresented: $isShowingAddSheet) {
            AddUpcomingItemSheet()
        }
        .sheet(item: $itemToEdit) { item in
            AddUpcomingItemSheet(itemToEdit: item)
        }
    }
    
    // MARK: - Helpers
    
    private func toggleFilter(_ category: UpcomingItem.UpcomingCategory) {
        if selectedFilters.contains(category) {
            selectedFilters.remove(category)
        } else {
            selectedFilters.insert(category)
        }
    }
    
    private func formatGroupDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInTomorrow(date) { return "Tomorrow" }
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
}

struct UnifiedUpcomingItemRow: View {
    let item: UpcomingView.UnifiedItem
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Category Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.isCalendar ? Theme.accentBlue.opacity(0.1) : (item.category?.color.opacity(0.1) ?? Color.gray.opacity(0.1)))
                    .frame(width: 44, height: 44)
                
                Image(systemName: item.isCalendar ? "calendar" : (item.category?.icon ?? "circle"))
                    .foregroundColor(item.isCalendar ? Theme.accentBlue : (item.category?.color ?? .gray))
                    .font(.system(size: 18))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Top Row: Title + Badges
                HStack(spacing: 8) {
                    Text(item.title)
                        .font(.system(size: 16, weight: .semibold))
                    
                    if item.isUrgent {
                        Text("URGENT")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    if item.isCalendar {
                        Text("Calendar")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.05))
                            .foregroundColor(Theme.textSecondary)
                            .cornerRadius(6)
                    } else if let cat = item.category {
                        Text(cat.rawValue)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.05))
                            .foregroundColor(Theme.textSecondary)
                            .cornerRadius(6)
                    }
                }
                
                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSecondary.opacity(0.8))
                        .lineLimit(1)
                }
                
                // Bottom Row: Date + Actions
                HStack {
                    Text(formatDate(item.date, includeTime: item.includeTime))
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                    
                    Spacer()
                    
                    // Hover Actions (Only for Manual Items)
                    if isHovering && !item.isCalendar {
                        HStack(spacing: 8) {
                            Button(action: onEdit) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.textSecondary)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: onDelete) {
                                Image(systemName: "trash")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.red.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                        }
                        .transition(.opacity)
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(item.isUrgent ? Color.red.opacity(0.3) : isHovering ? Color.white.opacity(0.1) : Color.white.opacity(0.05), lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
    
    func formatDate(_ date: Date, includeTime: Bool) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = includeTime ? .short : .none
        formatter.doesRelativeDateFormatting = true
        return formatter.string(from: date)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color.opacity(0.15) : Color.white.opacity(0.05))
                .foregroundColor(isSelected ? color : Theme.textSecondary)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? color.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
