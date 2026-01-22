/*
 Station > Views > Dashboard > AlertsBlock.swift
 -----------------------------------------------
 PURPOSE:
 This is the "Smart Notification" center of the dashboard.
 It scans all tasks and events to tell the user what they should panic about NOW.
 
 LOGIC:
 1. Eligibility: Only items within a specific time window (e.g. now + 60 mins).
 2. Prioritization: Urgent items ALWAYS override normal items.
 3. Sorting:
    - If "In the Past" (e.g. started 5 mins ago), priority goes to the MOST RECENT start time.
    - If "In the Future" (e.g. starts in 10 mins), priority goes to the SOONEST start time.
 */

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
    
    @ObservedObject var settings = SettingsManager.shared
    
    // Internal struct to unify candidates
    struct Candidate: Identifiable {
        let id: String
        let title: String
        let date: Date
        let isUrgent: Bool
    }
    
    // COMPUTED PROPERTY: Gather all possible alerts
    var currentAlertCandidates: [Candidate] {
        let now = Date()
        let showWindowSeconds = settings.alertTiming.secondsBefore
        let expireWindowSeconds = settings.autoDismissAlerts.seconds
        
        // Window thresholds:
        // [Expire Threshold] <--- NOW ---> [Show Threshold]
        let showThreshold = now.addingTimeInterval(showWindowSeconds)
        let expireThreshold = now.addingTimeInterval(-expireWindowSeconds)
        
        var candidates: [Candidate] = []
        var seenCalendarEventIDs = Set<String>() // Track calendar event IDs to prevent duplicates
        
        // 1. Upcoming Items
        // Logic: Include time is mandatory for alerts
        // Date must be within the alert window:
        // <= showThreshold (Time to show it)
        // >= expireThreshold (Hasn't auto-dismissed yet)
        let relevantItems = upcomingManager.items.filter { item in
            item.includeTime &&
            !upcomingManager.clearedAlertIDs.contains(item.id.uuidString) &&
            item.dueDate <= showThreshold &&
            item.dueDate >= expireThreshold
        }
        for item in relevantItems {
            candidates.append(Candidate(id: item.id.uuidString, title: item.title, date: item.dueDate, isUrgent: item.isUrgent))
        }
        
        // 2. Calendar Events - with deduplication
        if settings.includeCalendarInAlerts {
            let relevantEvents = calendarManager.events.filter { event in
                !upcomingManager.clearedAlertIDs.contains(event.id) &&
                event.startDate <= showThreshold &&
                event.startDate >= expireThreshold
            }
            
            for event in relevantEvents {
                // Deduplicate: Only add if we haven't seen this calendar event ID before
                guard !seenCalendarEventIDs.contains(event.id) else { continue }
                seenCalendarEventIDs.insert(event.id)
                
                candidates.append(Candidate(id: event.id, title: event.title, date: event.startDate, isUrgent: false))
            }
        }
        
        return candidates
    }
    
    // COMPUTED PROPERTY: Select the SINGLE BEST alert to show
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
        let absDiff = abs(diff)
        let minutes = Int(absDiff / 60)
        
        let urgentPrefix = isUrgent ? "URGENT · " : ""
        
        if diff > 0 {
            // Future
            if minutes < 60 {
                return "\(urgentPrefix)In \(minutes) min"
            } else {
                let hours = Int(absDiff / 3600)
                let suffix = hours == 1 ? "hr" : "hrs"
                return "\(urgentPrefix)In \(hours) \(suffix)"
            }
        } else {
            // Past
            if minutes < 60 {
                return "\(urgentPrefix)\(minutes) min ago"
            } else {
                let hours = Int(absDiff / 3600)
                let suffix = hours == 1 ? "hr" : "hrs"
                return "\(urgentPrefix)\(hours) \(suffix) ago"
            }
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
                StationEmptyState(icon: "bell.slash", message: "No alerts right now", includeBackground: true)
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

