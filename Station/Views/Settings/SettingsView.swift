/*
 Station > Views > Settings > SettingsView.swift
 -----------------------------------------------
 PURPOSE:
 The configuration screen for the user.
 
 ARCHITECTURE:
 - Uses a `Form` style layout (actually custom Cards in a ScrollView) for grouped settings.
 - Directly binds UI controls (Toggles, Pickers) to the `SettingsManager`.
 - Uses `ObservableObject` to update efficiently when settings change.
 */

import SwiftUI
import EventKit

struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    @EnvironmentObject var calendarManager: CalendarManager
    @EnvironmentObject var upcomingManager: UpcomingManager
    
    private var hasCalendarAccess: Bool {
        calendarManager.permissionStatus == .authorized || calendarManager.permissionStatus == .fullAccess
    }
    
    private var selectedCalendarsSummary: String {
        let count = settings.selectedCalendarIDs.count
        if count == 0 { return "None selected" }
        if count == calendarManager.availableCalendars.count { return "All calendars" }
        return "\(count) selected"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Settings")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                }
                .padding(.bottom, 8)
                
                // MARK: - Calendar
                SettingsSection(title: "CALENDARS", icon: "calendar") {
                    
                    if !hasCalendarAccess {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Calendar Access Required")
                                .font(.headline)
                                .foregroundColor(.orange)
                            Text("Station needs access to your calendar to display your classes and upcoming events.")
                                .font(.subheadline)
                                .foregroundColor(Theme.textSecondary)
                            Button("Grant Access") {
                                calendarManager.requestAccess()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    } else {
                        CalendarGroupRow(
                            title: "Your Calendars",
                            subtitle: selectedCalendarsSummary,
                            icon: "tray.full.fill"
                        ) {
                            ForEach(calendarManager.availableCalendars, id: \.calendarIdentifier) { calendar in
                                Toggle(isOn: Binding(
                                    get: { settings.selectedCalendarIDs.contains(calendar.calendarIdentifier) },
                                    set: { isSelected in
                                        if isSelected {
                                            settings.selectedCalendarIDs.insert(calendar.calendarIdentifier)
                                        } else {
                                            settings.selectedCalendarIDs.remove(calendar.calendarIdentifier)
                                        }
                                        calendarManager.fetchEvents()
                                    }
                                )) {
                                    HStack {
                                        Circle()
                                            .fill(Color(calendar.cgColor))
                                            .frame(width: 8, height: 8)
                                        Text(calendar.title)
                                            .foregroundColor(Theme.textPrimary)
                                        Spacer()
                                        Text(calendar.source.title)
                                            .font(.caption)
                                            .foregroundColor(Theme.textSecondary)
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: Theme.accentBlue))
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                
                // MARK: - Upcoming
                SettingsSection(title: "UPCOMING", icon: "clock.fill") {
                    SettingsToggleRow(
                        title: "Include Calendar Events",
                        icon: "calendar.badge.plus",
                        isOn: $settings.includeCalendarInUpcoming
                    )
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    SettingsPickerRow(
                        title: "Time Limit",
                        icon: "hourglass",
                        selection: $settings.upcomingTimeLimit
                    )
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    SettingsToggleRow(
                        title: "Group by Date",
                        icon: "rectangle.grid.1x2.fill",
                        isOn: $settings.groupUpcomingByDate
                    )
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    // Danger Zone: Clear Data
                    Button(action: {
                        upcomingManager.resetAllManualItems()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear All Manual Tasks")
                        }
                        .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 8)
                }
                
                // MARK: - Alerts
                SettingsSection(title: "ALERTS", icon: "bell.fill") {
                    SettingsToggleRow(
                        title: "Include Calendar Events",
                        icon: "bell.badge",
                        isOn: $settings.includeCalendarInAlerts
                    )
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    SettingsPickerRow(
                        title: "Show Alert",
                        icon: "timer",
                        selection: $settings.alertTiming
                    )
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    SettingsPickerRow(
                        title: "Auto-Dismiss After",
                        icon: "xmark.circle",
                        selection: $settings.autoDismissAlerts
                    )
                }
                
                // MARK: - General
                SettingsSection(title: "GENERAL", icon: "gear") {
                    SettingsPickerRow(
                        title: "Default Launch Tab",
                        icon: "arrow.up.left.and.arrow.down.right",
                        selection: $settings.defaultLaunchTab
                    )
                }
                
                VStack(spacing: 8) {
                    Text("Station v1.0")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary.opacity(0.5))
                    Text("Designed for Students")
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary.opacity(0.3))
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .padding(32)
        }
        .background(Theme.background)
        .foregroundColor(Theme.textPrimary)
    }
}

// MARK: - Helper Views

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.accentBlue)
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.textSecondary)
                    .tracking(1) // uppercase spacing
            }
            .padding(.leading, 4)
            
            VStack(spacing: 0) {
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
}

struct SettingsToggleRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Theme.textSecondary)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 14))
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Theme.accentBlue))
        }
        .padding(.vertical, 8)
    }
}

struct SettingsPickerRow<T: Hashable & Identifiable & RawRepresentable>: View where T.RawValue == String, T: CaseIterable {
    let title: String
    let icon: String
    @Binding var selection: T
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Theme.textSecondary)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 14))
            
            Spacer()
            
            Picker("", selection: $selection) {
                ForEach(Array(T.allCases), id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct CalendarGroupRow<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let content: Content
    
    @State private var isExpanded: Bool = false
    
    init(title: String, subtitle: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.system(size: 14))
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .foregroundColor(Theme.textSecondary)
                        .font(.system(size: 12))
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                Divider().background(Color.white.opacity(0.1))
                VStack(spacing: 0) {
                    content
                }
                .padding(.leading, 24) // Indent content
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
