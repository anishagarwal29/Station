import Foundation
internal import EventKit
import Combine

struct CalendarEvent: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let location: String?
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}

class CalendarManager: ObservableObject {
    @Published var events: [CalendarEvent] = []
    @Published var permissionStatus: EKAuthorizationStatus = .notDetermined
    
    private let eventStore = EKEventStore()
    
    // READ-ONLY: We request full access because iOS/macOS requires it to READ events.
    // We strictly DO NOT modify, create, or delete any events.
    func requestAccess() {
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    self.permissionStatus = EKEventStore.authorizationStatus(for: .event)
                    if granted {
                        self.fetchEvents()
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    self.permissionStatus = EKEventStore.authorizationStatus(for: .event)
                    if granted {
                        self.fetchEvents()
                    }
                }
            }
        }
    }
    
    func fetchEvents() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        // Fetch next 30 days to cover upcoming views
        let endOfSearch = calendar.date(byAdding: .day, value: 30, to: startOfDay)!
        
        // Filter for specific academic calendars
        let allCalendars = eventStore.calendars(for: .event)
        
        print("DEBUG: All Calendars found: \(allCalendars.map { $0.title })")
        
        // Relaxing filter for debugging - if strict "Studying"/"Exams" is failing, we might see why.
        let academicCalendars = allCalendars.filter { calendar in
            let title = calendar.title.lowercased()
            return title == "studying" || title == "exams"
        }
        
        print("DEBUG: Academic Calendars filtered: \(academicCalendars.map { $0.title })")
        
        // NOTE: If academicCalendars is empty, passing nil fetches from ALL calendars.
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfSearch, calendars: academicCalendars.isEmpty ? nil : academicCalendars) 
        
        let ekEvents = eventStore.events(matching: predicate)
        print("DEBUG: Events fetched count: \(ekEvents.count)")
        
        self.events = ekEvents
            .filter { !$0.isAllDay } // We only want classes/scheduled events
            .map { ekEvent in
                CalendarEvent(
                    id: ekEvent.eventIdentifier,
                    title: ekEvent.title ?? "Untitled",
                    startDate: ekEvent.startDate,
                    endDate: ekEvent.endDate,
                    location: ekEvent.location
                )
            }
            .sorted { $0.startDate < $1.startDate }
    }
}
