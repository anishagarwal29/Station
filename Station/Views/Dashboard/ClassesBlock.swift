import SwiftUI
internal import EventKit

struct ClassesBlock: View {
    @EnvironmentObject var calendarManager: CalendarManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                let todaysEvents = calendarManager.events.filter { Calendar.current.isDateInToday($0.startDate) }
                
                if todaysEvents.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 32))
                            .foregroundColor(Theme.textSecondary.opacity(0.5))
                        Text(calendarManager.permissionStatus == .authorized ? "No events scheduled for today" : "Calendar access needed")
                            .foregroundColor(Theme.textSecondary)
                        
                        if calendarManager.permissionStatus != .authorized {
                            Button("Grant Access") {
                                calendarManager.requestAccess()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Theme.accentBlue)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(Theme.cardBackground)
                    .cornerRadius(Theme.cornerRadius)
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
        }
    }
    
    private func getEventStatus(event: CalendarEvent, allEvents: [CalendarEvent]) -> EventStatus {
        let now = Date()
        
        // Is it happening now?
        if now >= event.startDate && now <= event.endDate {
            return .now
        }
        
        // Find the next upcoming event
        // The first event that hasn't started yet
        let upcomingEvents = allEvents.filter { $0.startDate > now }
        if let firstUpcoming = upcomingEvents.first, firstUpcoming.id == event.id {
            return .next
        }
        
        return .none
    }
    
    private func getIcon(for title: String) -> String {
        let lowerTitle = title.lowercased()
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
