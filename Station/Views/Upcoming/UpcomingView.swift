import SwiftUI

struct UpcomingView: View {
    @EnvironmentObject var upcomingManager: UpcomingManager
    @EnvironmentObject var calendarManager: CalendarManager
    @State private var isShowingAddSheet = false
    @State private var itemToEdit: UpcomingItem?
    
    // Unified display item that can represent both manual items and calendar events
    struct UnifiedUpcomingItem: Identifiable {
        let id: String
        let title: String
        let date: Date
        let description: String
        let category: UpcomingItem.UpcomingCategory
        let isUrgent: Bool
        let includeTime: Bool
        let isCalendarEvent: Bool
        let originalItemId: UUID?
    }
    
    var allUpcomingItems: [UnifiedUpcomingItem] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        
        var unified: [UnifiedUpcomingItem] = []
        var seenCalendarEventIDs = Set<String>() // Track calendar event IDs to prevent duplicates
        
        // 1. Manual Items (from today onwards, excluding cleared alerts)
        let relevantManualItems = upcomingManager.items.filter { item in
            item.dueDate >= startOfToday && !upcomingManager.clearedAlertIDs.contains(item.id.uuidString)
        }
        
        for item in relevantManualItems {
            unified.append(UnifiedUpcomingItem(
                id: "manual_\(item.id.uuidString)",
                title: item.title,
                date: item.dueDate,
                description: item.description,
                category: item.category,
                isUrgent: item.isUrgent,
                includeTime: item.includeTime,
                isCalendarEvent: false,
                originalItemId: item.id
            ))
        }
        
        // 2. Calendar Events (from today onwards) - with deduplication
        let relevantCalendarEvents = calendarManager.events.filter { $0.startDate >= startOfToday }
        
        for event in relevantCalendarEvents {
            // Deduplicate: Only add if we haven't seen this calendar event ID before
            guard !seenCalendarEventIDs.contains(event.id) else { continue }
            seenCalendarEventIDs.insert(event.id)
            
            unified.append(UnifiedUpcomingItem(
                id: "calendar_\(event.id)",
                title: event.title,
                date: event.startDate,
                description: event.location ?? "",
                category: .event,
                isUrgent: false,
                includeTime: true,
                isCalendarEvent: true,
                originalItemId: nil
            ))
        }
        
        // Sort strictly by date/time
        return unified.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Upcoming")
                        .font(.system(size: 32, weight: .bold))
                    Text("Your unified schedule for the coming weeks")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                
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
            .padding(.horizontal, 40)
            .padding(.top, 40)
            .padding(.bottom, 24)
            
            ScrollView {
                if allUpcomingItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.textSecondary.opacity(0.5))
                        Text("No upcoming items")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.textSecondary)
                        Button("Add Item") {
                            isShowingAddSheet = true
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Theme.accentBlue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    VStack(spacing: 12) {
                        ForEach(allUpcomingItems) { item in
                            UnifiedUpcomingItemRow(
                                item: item,
                                onEdit: {
                                    if !item.isCalendarEvent, let originalId = item.originalItemId {
                                        if let originalItem = upcomingManager.items.first(where: { $0.id == originalId }) {
                                            itemToEdit = originalItem
                                        }
                                    }
                                },
                                onDelete: {
                                    if !item.isCalendarEvent, let originalId = item.originalItemId {
                                        upcomingManager.deleteItem(id: originalId)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
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
}

struct UnifiedUpcomingItemRow: View {
    let item: UpcomingView.UnifiedUpcomingItem
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Category Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.category.color.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: item.category.icon)
                    .foregroundColor(item.category.color)
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
                    
                    // Calendar badge or category badge
                    if item.isCalendarEvent {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 9))
                            Text("Calendar")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.accentBlue.opacity(0.15))
                        .foregroundColor(Theme.accentBlue)
                        .cornerRadius(6)
                    } else {
                        Text(item.category.rawValue)
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
                    
                    // Hover Actions (only for manual items)
                    if isHovering && !item.isCalendarEvent {
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

struct UpcomingView_Previews: PreviewProvider {
    static var previews: some View {
        UpcomingView()
    }
}
