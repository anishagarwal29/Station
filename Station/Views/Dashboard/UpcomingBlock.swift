/*
 Station > Views > Dashboard > UpcomingBlock.swift
 -------------------------------------------------
 PURPOSE:
 Shows a preview of what's coming up "Tomorrow and Beyond".
 
 LOGIC:
 1. Aggregates data from two sources:
    - Manual Items (from UpcomingManager)
    - Calendar Events (from CalendarManager)
 2. Filters strictly for dates starting TOMORROW (Today is covered by ClassesBlock).
 3. Sorts by date and picks only the top 2 for a compact view.
 */

import SwiftUI

struct UpcomingBlock: View {
    @EnvironmentObject var upcomingManager: UpcomingManager
    @EnvironmentObject var calendarManager: CalendarManager
    
    // We observe settings to know if we should include calendar items here.
    @ObservedObject var settings = SettingsManager.shared
    
    // An internal Struct to unify the two different data types (Task vs Event) into one view model.
    struct UpcomingDisplayItem: Identifiable {
        let id: String
        let title: String
        let date: Date
        let detail: String?
        let typeBadge: String
        let isUrgent: Bool
    }
    
    // COMPUTED PROPERTY:
    // This does all the heavy lifting of merging, filtering, and sorting.
    var visibleItems: [UpcomingDisplayItem] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        
        // "Upcoming → future only" (Tomorrow onwards)
        // If we can't calculate tomorrow, return empty.
        guard let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) else { return [] }
        
        // Calculate cutoff date based on settings (e.g. Next 3 Days, Next 7 Days)
        var cutoffDate: Date?
        if let days = settings.upcomingTimeLimit.days {
            cutoffDate = calendar.date(byAdding: .day, value: days, to: startOfTomorrow)
        }
        
        var displayed: [UpcomingDisplayItem] = []
        var seenCalendarEventIDs = Set<String>() // Track IDs to prevent duplicates if calc runs multiple times
        
        // 1. Manual Items (From start of tomorrow onwards)
        let relevantTasks = upcomingManager.items.filter { item in
            var valid = item.dueDate >= startOfTomorrow
            if let cutoff = cutoffDate {
                valid = valid && item.dueDate <= cutoff
            }
            return valid
        }
        
        for task in relevantTasks {
            displayed.append(UpcomingDisplayItem(
                id: "task_\(task.id.uuidString)",
                title: task.title,
                date: task.dueDate,
                detail: task.description.isEmpty ? nil : task.description,
                typeBadge: task.category.rawValue,
                isUrgent: task.isUrgent
            ))
        }
        
        // 2. Calendar Events (From start of tomorrow onwards, if enabled)
        if settings.includeCalendarInUpcoming {
            let relevantEvents = calendarManager.events.filter { event in
                var valid = event.startDate >= startOfTomorrow
                if let cutoff = cutoffDate {
                    valid = valid && event.startDate <= cutoff
                }
                return valid
            }
            
            for event in relevantEvents {
                // Deduplicate: Only add if we haven't seen this calendar event ID before
                guard !seenCalendarEventIDs.contains(event.id) else { continue }
                seenCalendarEventIDs.insert(event.id)
                
                displayed.append(UpcomingDisplayItem(
                    id: "cal_\(event.id)",
                    title: event.title,
                    date: event.startDate,
                    detail: event.location, 
                    typeBadge: "Event",
                    isUrgent: false
                ))
            }
        }
        
        // Sort strictly by date/time (Soonest first) and take MAX 2
        return Array(displayed.sorted { $0.date < $1.date }.prefix(2))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Upcoming")
                .font(.system(size: 20, weight: .bold))
            
            if visibleItems.isEmpty {
                // Empty State
                HStack {
                    Text("No upcoming events")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary.opacity(0.5))
                    Spacer()
                }
                .padding(Theme.padding)
                .background(Theme.cardBackground.opacity(0.5))
                .cornerRadius(Theme.cornerRadius)
            } else {
                // 2-Column Grid
                // We use LazyVGrid with flexible columns to fit side-by-side if width permits
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(visibleItems) { item in
                        UpcomingCard(item: item)
                    }
                }
            }
        }
    }
}

struct UpcomingCard: View {
    let item: UpcomingBlock.UpcomingDisplayItem
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM · EEEE" // 22 JAN · THURSDAY
        return formatter.string(from: item.date).uppercased()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top Row: Date + Badge
            HStack {
                Text(formattedDate)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.textSecondary)
                
                Spacer()
                
                Text(item.typeBadge)
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.05))
                    .foregroundColor(Theme.textSecondary)
                    .cornerRadius(4)
            }
            
            Spacer()
            
            // Content Block
            VStack(alignment: .leading, spacing: 4) {
                // Main Title + Urgent
                HStack(spacing: 6) {
                    if item.isUrgent {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textSecondary)
                    }
                    
                    Text(item.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                }
                
                // Subtitle (Always reserve space)
                Text(item.detail?.isEmpty == false ? item.detail! : " ")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(1)
                    .opacity(item.detail?.isEmpty == false ? 1 : 0)
            }
        }
        .padding(Theme.padding)
        .frame(height: 100) // Fixed height
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}
