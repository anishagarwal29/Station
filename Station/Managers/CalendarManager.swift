import Foundation
import EventKit
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
    @Published var availableCalendars: [EKCalendar] = []
    
    private let eventStore = EKEventStore()
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(storeChanged), name: .EKEventStoreChanged, object: nil)
    }
    
    @objc private func storeChanged() {
        DispatchQueue.main.async {
            self.fetchEvents()
        }
    }
    
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
        
        // 1. Fetch and publish available calendars so Settings can list them
        let allCalendars = eventStore.calendars(for: .event)
        
        // Deduplicate
        let unique = Dictionary(grouping: allCalendars, by: { $0.calendarIdentifier })
            .compactMap { $0.value.first }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            
        DispatchQueue.main.async {
            self.availableCalendars = unique
        }
        
        // 2. Filter based on SettingsManager selection
        // "Only events from toggled calendars should appear"
        let selectedIDs = SettingsManager.shared.selectedCalendarIDs
        let calendarsToFetch = allCalendars.filter { selectedIDs.contains($0.calendarIdentifier) }
        
        // If nothing is toggled, showing nothing is the correct behavior per constraints.
        // However, for UX, if NO calendars are selected effectively (empty set), we return empty.
        if calendarsToFetch.isEmpty {
            DispatchQueue.main.async {
                self.events = []
            }
            return
        }
        
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfSearch, calendars: calendarsToFetch)
        
        let ekEvents = eventStore.events(matching: predicate)
        
        // Deduplicate events (Title + Date)
        // This handles cases where the same logical event exists in multiple calendars (e.g. iCloud + Google)
        var seenKeys = Set<String>()
        var uniqueEvents: [EKEvent] = []
        
        // Sort by startDate to ensure order
        for event in ekEvents.sorted(by: { $0.startDate < $1.startDate }) {
            // Create a unique key based on Title and Start Time
            let key = "\(event.title ?? "")|\(Int(event.startDate.timeIntervalSince1970))"
            
            if !seenKeys.contains(key) {
                seenKeys.insert(key)
                uniqueEvents.append(event)
            }
        }
        
        DispatchQueue.main.async {
            self.events = uniqueEvents
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
}
