/*
 Station > Managers > CalendarManager.swift
 ------------------------------------------
 PURPOSE:
 This class handles all interaction with the Apple Calendar (EventKit).
 It communicates with the OS to fetch events and provides them to the app.
 
 CRITICAL:
 - This is strictly READ-ONLY. We do not edit, delete, or create OS calendar events.
 - It works in tandem with SettingsManager to only show calendars the user cares about.
 */

import Foundation
import EventKit
import Combine

/*
 STRUCT: CalendarEvent
 ---------------------
 A simplified version of Apple's `EKEvent`.
 We map the messy system event object into this clean struct for use in our UI.
 Identifiable ensures it plays nicely with SwiftUI lists.
 */
struct CalendarEvent: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let location: String?
    
    // Helper to print "10:00 - 11:30"
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}

class CalendarManager: ObservableObject {
    // EVENTS: The final, filtered, deduplicated list of events ready for the UI.
    @Published var events: [CalendarEvent] = []
    
    // PERMISSIONS: We need to know if the user said "Yes" to calendar access.
    @Published var permissionStatus: EKAuthorizationStatus = .notDetermined
    
    // CALENDARS: A list of all calendars (iCloud, Google, etc.) found on the device.
    @Published var availableCalendars: [EKCalendar] = []
    
    // The main object provided by Apple Frameworks to talk to the Calendar Database.
    private let eventStore = EKEventStore()
    
    init() {
        // Observer: Listens for external changes. If you add an event in the Calendar App,
        // this notification tells us to refresh our data instantly.
        NotificationCenter.default.addObserver(self, selector: #selector(storeChanged), name: .EKEventStoreChanged, object: nil)
    }
    
    @objc private func storeChanged() {
        DispatchQueue.main.async {
            self.fetchEvents()
        }
    }
    
    // MARK: - Permissions
    
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
            // Fallback for older macOS versions
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
    
    // MARK: - Core Logic: Fetching
    
    func fetchEvents() {
        // Define the Time Window: Today to +30 Days.
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfSearch = calendar.date(byAdding: .day, value: 30, to: startOfDay)!
        
        // 1. Fetch and publish available calendars so Settings can list them
        let allCalendars = eventStore.calendars(for: .event)
        
        // Deduplicate Logic (for Calendars):
        // Sometimes duplicate calendars appear (e.g. local vs cloud mirrors).
        // We group by ID and pick one.
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
        
        // Query the EventStore
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfSearch, calendars: calendarsToFetch)
        let ekEvents = eventStore.events(matching: predicate)
        
        // 3. Deduplicate events (Title + Date)
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
        
        // 4. Map to our clean struct
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
