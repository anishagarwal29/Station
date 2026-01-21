import SwiftUI

struct AlertsBlock: View {
    @EnvironmentObject var upcomingManager: UpcomingManager
    @EnvironmentObject var calendarManager: CalendarManager
    
    // Model for alerts
    struct AlertItem: Identifiable {
        let id: String
        let title: String
        let time: Date
        let detail: String
        let isUrgent: Bool
        let isPast: Bool
    }
    
    // Internal struct to unify candidates
    struct Candidate: Identifiable {
        let id: String
        let title: String
        let date: Date
        let isUrgent: Bool
    }
    
    var currentAlertCandidates: [Candidate] {
        let now = Date()
        let fifteenMinutesAgo = now.addingTimeInterval(-900)
        
        var candidates: [Candidate] = []
        var seenCalendarEventIDs = Set<String>() // Track calendar event IDs to prevent duplicates
        
        // 1. Upcoming Items
        let relevantItems = upcomingManager.items.filter { item in
            item.includeTime &&
            item.dueDate > fifteenMinutesAgo &&
            !upcomingManager.clearedAlertIDs.contains(item.id.uuidString)
        }
        for item in relevantItems {
            candidates.append(Candidate(id: item.id.uuidString, title: item.title, date: item.dueDate, isUrgent: item.isUrgent))
        }
        
        // 2. Calendar Events - with deduplication
        // Filter: Start date within valid window (future or < 15m ago)
        // AND not cleared (we use event.id as the ID for clearing)
        let relevantEvents = calendarManager.events.filter { event in
            event.startDate > fifteenMinutesAgo &&
            !upcomingManager.clearedAlertIDs.contains(event.id)
        }
        
        for event in relevantEvents {
            // Deduplicate: Only add if we haven't seen this calendar event ID before
            guard !seenCalendarEventIDs.contains(event.id) else { continue }
            seenCalendarEventIDs.insert(event.id)
            
            candidates.append(Candidate(id: event.id, title: event.title, date: event.startDate, isUrgent: false))
        }
        
        return candidates
    }
    
    var alert: AlertItem? {
        let now = Date()
        
        // 1. Get all valid candidates
        let candidates = currentAlertCandidates
        if candidates.isEmpty { return nil }
        
        // 2. Priority Rule: Urgent > Non-Urgent
        // If there are any urgent items, strictly ignore non-urgent ones
        let hasUrgent = candidates.contains { $0.isUrgent }
        let prioritizedCandidates = hasUrgent ? candidates.filter { $0.isUrgent } : candidates
        
        // 3. Timing/Switching Logic
        // Split into "Past/Now" (<= now) and "Future" (> now)
        let pastItems = prioritizedCandidates.filter { $0.date <= now }
        let futureItems = prioritizedCandidates.filter { $0.date > now }
        
        var selectedItem: Candidate?
        
        if !pastItems.isEmpty {
            // Rule: "Switch to newer item" when time is reached.
            // If we have items that have happened (Past), we want the one that happened MOST RECENTLY (Latest Date).
            selectedItem = pastItems.sorted(by: { $0.date > $1.date }).first
        } else {
            // No past items, only Future.
            // Pick the nearest upcoming (Earliest Date).
            selectedItem = futureItems.sorted(by: { $0.date < $1.date }).first
        }
        
        guard let item = selectedItem else { return nil }
        
        let isPast = item.date <= now
        let timeString = formatRelativeTime(from: now, to: item.date, isUrgent: item.isUrgent)
        
        return AlertItem(
            id: item.id,
            title: item.title,
            time: item.date,
            detail: timeString,
            isUrgent: item.isUrgent,
            isPast: isPast
        )
    }
    
    func formatRelativeTime(from now: Date, to date: Date, isUrgent: Bool) -> String {
        let diff = date.timeIntervalSince(now)
        let minutes = Int(abs(diff) / 60)
        
        let urgentPrefix = isUrgent ? "URGENT · " : ""
        
        if diff > 0 {
            // Future
            return "\(urgentPrefix)In \(minutes) min"
        } else {
            // Past
            return "\(urgentPrefix)\(minutes) min ago"
        }
    }
    
    var body: some View {
        let activeAlert = alert
        
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Alerts")
                    .font(.system(size: 20, weight: .bold))
                
                Spacer()
                
                // Show Clear All only if there is an active alert displayed
                if let currentAlert = activeAlert {
                    Button(action: {
                        // Clear ONLY the currently displayed alert
                        // This allows the next eligible item (if any) to automatically populate
                        upcomingManager.markAlertsAsCleared(ids: [currentAlert.id])
                    }) {
                        Text("Clear All")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if let displayedAlert = activeAlert {
                AlertCard(alert: displayedAlert)
            } else {
                HStack {
                    Text("No alerts right now")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary.opacity(0.5))
                    Spacer()
                }
                .padding(Theme.padding)
                .background(Theme.cardBackground.opacity(0.5))
                .cornerRadius(Theme.cornerRadius)
            }
        }
    }
}

struct AlertCard: View {
    let alert: AlertsBlock.AlertItem
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(alert.isUrgent ? Color.red.opacity(0.1) : Theme.accentBlue.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: alert.isUrgent ? "exclamationmark.triangle.fill" : "bell.fill")
                    .foregroundColor(alert.isUrgent ? .red : Theme.accentBlue)
                    .font(.system(size: 20))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Status Text (e.g., URGENT · In 5 min)
                Text(alert.detail)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(alert.isUrgent ? .red : Theme.accentBlue)
                    .textCase(.uppercase)
                
                // Title
                Text(alert.title)
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(Theme.padding)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(alert.isUrgent ? Color.red.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

