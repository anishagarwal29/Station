/*
 Station > Views > Dashboard > ClassesBlock.swift
 ------------------------------------------------
 PURPOSE:
 This block displays "Today's Schedule".
 It connects to the CalendarManager (Read-Only) to show what classes you have right now.
 
 LOGIC:
 - Filters: Only shows events happening TODAY.
 - Status: Calculates if an event is happening "NOW" or is "NEXT" to highlight it visually.
 - Icons: Guesses the subject icon (e.g. "Math" -> Calculator) based on the event title.
 */

import SwiftUI
import EventKit
import Combine

struct ClassesBlock: View {
    @EnvironmentObject var calendarManager: CalendarManager
    
    // State to trigger minute-by-minute updates
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Today's Classes")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                Button(action: { calendarManager.fetchEvents() }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(Theme.textSecondary)
                }
                .buttonStyle(.plain)
                
                Image(systemName: "calendar")
                    .foregroundColor(Theme.textSecondary)
            }
            
            VStack(spacing: 12) {
                // Filter Logic:
                // 1. Must be TODAY.
                // 2. Must NOT be over (endDate > now).
                let todaysEvents = calendarManager.events.filter { event in
                    Calendar.current.isDateInToday(event.startDate) && event.endDate > currentTime
                }
                
                if todaysEvents.isEmpty {
                    if calendarManager.permissionStatus == .authorized {
                        StationEmptyState(icon: "calendar.badge.clock", message: "No upcoming classes today", includeBackground: true)
                    } else {
                        VStack(spacing: 12) {
                            StationEmptyState(icon: "lock.fill", message: "Calendar access needed")
                            Button("Grant Access") {
                                calendarManager.requestAccess()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Theme.accentBlue)
                        }
                        .padding(12)
                        .background(Theme.cardBackground.opacity(0.5))
                        .cornerRadius(Theme.cornerRadius)
                    }
                } else {
                    ForEach(Array(todaysEvents.enumerated()), id: \.element.id) { index, event in
                        let status = getEventStatus(event: event, allEvents: todaysEvents)
                        ClassCard(
                            title: event.title,
                            time: event.timeString,
                            location: event.location ?? "No location",
                            icon: getIcon(for: event.title),
                            status: status
                        )
                    }
                }
            }
        }
        .onAppear {
            calendarManager.requestAccess()
            // Initialize time strictly
            currentTime = Date() 
        }
        .onReceive(timer) { input in
             currentTime = input
        }
    }
    
    // MARK: - Status Logic
    
    private func getEventStatus(event: CalendarEvent, allEvents: [CalendarEvent]) -> EventStatus {
        // Use the synchronized time
        let now = currentTime
        
        // Is it happening now?
        if now >= event.startDate && now <= event.endDate {
            return .now
        }
        
        // Find the next upcoming event
        // The first event that hasn't started yet
        let upcomingEvents = allEvents.filter { $0.startDate > now }
        // If this event matches the *first* one in the future list, it is "Next".
        if let firstUpcoming = upcomingEvents.first, firstUpcoming.id == event.id {
            return .next
        }
        
        return .none
    }
    
    private func getIcon(for title: String) -> String {
        let lowerTitle = title.lowercased()
        // Heuristic mapping for common subjects
        if lowerTitle.contains("physics") || lowerTitle.contains("science") { return "flask.fill" }
        if lowerTitle.contains("english") || lowerTitle.contains("lit") { return "book.fill" }
        if lowerTitle.contains("math") || lowerTitle.contains("calc") { return "sum" }
        if lowerTitle.contains("gym") || lowerTitle.contains("pe") { return "figure.run" }
        if lowerTitle.contains("history") { return "landmark.fill" }
        if lowerTitle.contains("art") { return "paintbrush.fill" }
        if lowerTitle.contains("music") { return "music.note" }
        return "graduationcap.fill"
    }
}

enum EventStatus {
    case now
    case next
    case none
}

struct ClassCard: View {
    let title: String
    let time: String
    let location: String
    let icon: String
    let status: EventStatus
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .foregroundColor(status == .now ? Theme.accentBlue : Theme.textSecondary)
                    .font(.system(size: 20))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                    
                    if status == .now {
                        Text("NOW")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Theme.accentBlue)
                            .cornerRadius(4)
                    } else if status == .next {
                        Text("NEXT")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    if status == .now {
                        Circle()
                            .fill(Theme.accentBlue)
                            .frame(width: 8, height: 8)
                    }
                }
                
                Text("\(time) • \(location)")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(Theme.padding)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(status == .now ? Theme.accentBlue.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
