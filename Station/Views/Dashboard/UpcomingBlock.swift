import SwiftUI

struct UpcomingBlock: View {
    @EnvironmentObject var upcomingManager: UpcomingManager
    @EnvironmentObject var calendarManager: CalendarManager
    
    struct UpcomingDisplayItem: Identifiable {
        let id: String
        let title: String
        let date: Date
        let detail: String?
        let typeBadge: String
        let isUrgent: Bool
    }
    
    var visibleItems: [UpcomingDisplayItem] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        // "Upcoming → future only" (Tomorrow onwards)
        guard let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) else { return [] }
        
        var displayed: [UpcomingDisplayItem] = []
        var seenCalendarEventIDs = Set<String>() // Track calendar event IDs to prevent duplicates
        
        // 1. Manual Items (From start of tomorrow onwards)
        let relevantTasks = upcomingManager.items.filter { $0.dueDate >= startOfTomorrow }
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
        
        // 2. Calendar Events (From start of tomorrow onwards) - with deduplication
        let relevantEvents = calendarManager.events.filter { $0.startDate >= startOfTomorrow }
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
        
        // Sort strictly by date/time and take MAX 2
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
