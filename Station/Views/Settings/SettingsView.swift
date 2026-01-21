import SwiftUI
import EventKit

struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    @EnvironmentObject var calendarManager: CalendarManager
    @EnvironmentObject var upcomingManager: UpcomingManager
    @State private var showingResetAlert = false
    
    @State private var isCalendarsExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Settings")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Text("Configure your preferences")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.horizontal, 40)
            .padding(.top, 40)
            .padding(.bottom, 24)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    
                    // --- Calendar Settings ---
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Calendar Settings")
                            .font(.headline)
                            .foregroundColor(Theme.textPrimary)
                            .padding(.horizontal, 4)
                        
                        SettingsCard {
                            if hasCalendarAccess {
                                if calendarManager.availableCalendars.isEmpty {
                                    Text("No calendars found.")
                                        .foregroundColor(Theme.textSecondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                } else {
                                    VStack(spacing: 0) {
                                        // Expandable Header
                                        Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isCalendarsExpanded.toggle() } }) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 6) {
                                                    Text("Select Calendars")
                                                        .foregroundColor(Theme.textPrimary)
                                                        .font(.system(size: 15, weight: .semibold))
                                                    
                                                    Text(selectedCalendarsSummary)
                                                        .font(.system(size: 13))
                                                        .foregroundColor(Theme.textSecondary)
                                                        .lineLimit(1)
                                                }
                                                Spacer()
                                                
                                                Circle()
                                                    .fill(Color.white.opacity(0.05))
                                                    .frame(width: 28, height: 28)
                                                    .overlay(
                                                        Image(systemName: "chevron.right")
                                                            .font(.system(size: 12, weight: .bold))
                                                            .foregroundColor(Theme.textSecondary)
                                                            .rotationEffect(.degrees(isCalendarsExpanded ? 90 : 0))
                                                    )
                                            }
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                        .padding(.vertical, 8)
                                        
                                        if isCalendarsExpanded {
                                            Rectangle()
                                                .fill(Color.white.opacity(0.1))
                                                .frame(height: 1)
                                                .padding(.vertical, 12)
                                            
                                            // Group calendars by Title
                                            let groups = Dictionary(grouping: calendarManager.availableCalendars, by: { $0.title })
                                            let sortedTitles = groups.keys.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
                                            
                                            ForEach(Array(sortedTitles.enumerated()), id: \.element) { index, title in
                                                if let calendars = groups[title], let firstCalendar = calendars.first {
                                                    CalendarGroupRow(
                                                        title: title,
                                                        color: Color(firstCalendar.color),
                                                        calendars: calendars,
                                                        settings: settings
                                                    ) {
                                                        calendarManager.fetchEvents()
                                                    }
                                                    .padding(.vertical, 4)
                                                    
                                                    if index < sortedTitles.count - 1 {
                                                        Rectangle()
                                                            .fill(Color.white.opacity(0.05))
                                                            .frame(height: 1)
                                                            .padding(.leading, 24)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            } else {
                                HStack {
                                    Text("Calendar access required")
                                        .foregroundColor(Theme.textSecondary)
                                    Spacer()
                                    Button("Request Access") {
                                        calendarManager.requestAccess()
                                    }
                                }
                            }
                        }
                        
                        if hasCalendarAccess {
                            Text("Calendars toggled ON are treated as Studying calendars.")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary.opacity(0.7))
                                .padding(.horizontal, 4)
                        }
                    }
                    
                    // --- Upcoming Settings ---
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upcoming Settings")
                            .font(.headline)
                            .foregroundColor(Theme.textPrimary)
                            .padding(.horizontal, 4)
                        
                        SettingsCard {
                            SettingsToggleRow(title: "Include calendar events", isOn: $settings.includeCalendarInUpcoming)
                            Divider().background(Color.white.opacity(0.1))
                            
                            HStack {
                                Text("Limit Upcoming to")
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                                Picker("", selection: $settings.upcomingTimeLimit) {
                                    ForEach(SettingsManager.UpcomingTimeLimit.allCases) { limit in
                                        Text(limit.rawValue).tag(limit)
                                    }
                                }
                                .labelsHidden()
                                .fixedSize()
                            }
                            .padding(.vertical, 4)
                            
                            Divider().background(Color.white.opacity(0.1))
                            SettingsToggleRow(title: "Group Upcoming items by date", isOn: $settings.groupUpcomingByDate)
                        }
                    }
                    
                    // --- Alerts Settings ---
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Alerts Settings")
                            .font(.headline)
                            .foregroundColor(Theme.textPrimary)
                            .padding(.horizontal, 4)
                        
                        SettingsCard {
                            SettingsToggleRow(title: "Include calendar events in alerts", isOn: $settings.includeCalendarInAlerts)
                            Divider().background(Color.white.opacity(0.1))
                            
                            HStack {
                                Text("Alert timing")
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                                Picker("", selection: $settings.alertTiming) {
                                    ForEach(SettingsManager.AlertTiming.allCases) { timing in
                                        Text(timing.rawValue).tag(timing)
                                    }
                                }
                                .labelsHidden()
                                .fixedSize()
                            }
                            .padding(.vertical, 4)
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            HStack {
                                Text("Auto-dismiss alerts after")
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                                Picker("", selection: $settings.autoDismissAlerts) {
                                    ForEach(SettingsManager.AutoDismissInterval.allCases) { interval in
                                        Text(interval.rawValue).tag(interval)
                                    }
                                }
                                .labelsHidden()
                                .fixedSize()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // --- General Settings ---
                    VStack(alignment: .leading, spacing: 12) {
                        Text("General")
                            .font(.headline)
                            .foregroundColor(Theme.textPrimary)
                            .padding(.horizontal, 4)
                        
                        SettingsCard {
                            HStack {
                                Text("Default launch tab")
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                                Picker("", selection: $settings.defaultLaunchTab) {
                                    ForEach(SettingsManager.Tab.allCases) { tab in
                                        Text(tab.rawValue).tag(tab)
                                    }
                                }
                                .pickerStyle(.segmented) // Segmented looks nice for tabs
                                .fixedSize()
                            }
                            .padding(.vertical, 4)
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            HStack {
                                Text("Reset manual upcoming items")
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                                Button("Reset") {
                                    showingResetAlert = true
                                }
                                .foregroundColor(.red)
                                .opacity(0.8)
                            }
                            .padding(.vertical, 4)
                            .alert("Reset Items?", isPresented: $showingResetAlert) {
                                Button("Cancel", role: .cancel) { }
                                Button("Reset", role: .destructive) {
                                    upcomingManager.resetAllManualItems()
                                }
                            } message: {
                                Text("This will delete all manually added upcoming items. Calendar data will not be affected.")
                            }
                        }
                    }
                    
                    // --- About ---
                    VStack(spacing: 8) {
                        Text("Station v1.0.0")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                    
                }
                .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
    }
    
    private var hasCalendarAccess: Bool {
        if calendarManager.permissionStatus == .authorized { return true }
        if #available(macOS 14.0, *) {
            if calendarManager.permissionStatus == .fullAccess { return true }
        }
        return false
    }
    
    private var selectedCalendarsSummary: String {
        let count = settings.selectedCalendarIDs.count
        if count == 0 { return "No calendars selected" }
        
        // Map ID to Title, deduplicate
        let titles = calendarManager.availableCalendars
            .filter { settings.selectedCalendarIDs.contains($0.calendarIdentifier) }
            .map { $0.title }
        
        let uniqueTitles = Array(Set(titles)).sorted()
        
        if uniqueTitles.isEmpty { return "\(count) calendars selected" }
        if uniqueTitles.count <= 3 {
            return uniqueTitles.joined(separator: ", ")
        }
        return "\(uniqueTitles.prefix(3).joined(separator: ", ")) + \(uniqueTitles.count - 3) more"
    }
}

// MARK: - Helper Views

struct SettingsCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 12) {
            content
        }
        .padding(16)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

struct SettingsToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(Theme.textPrimary)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch) // Switch style looks solid on macOS
        }
        .padding(.vertical, 4)
    }
}

struct CalendarGroupRow: View {
    let title: String
    let color: Color
    let calendars: [EKCalendar]
    @ObservedObject var settings: SettingsManager
    let onChange: () -> Void
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(title)
                .foregroundColor(Theme.textPrimary)
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: {
                    // Display as ON if ANY calendar in the group is selected
                    !calendars.isEmpty && calendars.contains { settings.selectedCalendarIDs.contains($0.calendarIdentifier) }
                },
                set: { isOn in
                    for calendar in calendars {
                        if isOn {
                            settings.selectedCalendarIDs.insert(calendar.calendarIdentifier)
                        } else {
                            settings.selectedCalendarIDs.remove(calendar.calendarIdentifier)
                        }
                    }
                    onChange()
                }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
        }
        .padding(.vertical, 4)
    }
}
