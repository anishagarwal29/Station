/*
 Station > Managers > SettingsManager.swift
 ------------------------------------------
 PURPOSE:
 This class persists User Preferences (like which calendars to show or what tab to open first).
 
 PATTERNS:
 - Singleton: `SettingsManager.shared` ensures there is only ONE settings object for the whole app.
 - Persistence: It saves every change instantly to `UserDefaults` so your settings are remembered after a restart.
 */

import Foundation
import SwiftUI
import Combine

class SettingsManager: ObservableObject {
    // SINGLETON ACCESS: We use this static property to access settings from anywhere.
    static let shared = SettingsManager()
    
    // MARK: - Calendar Settings
    
    // Note: We use `didSet` on every property to trigger an auto-save locally.
    @Published var selectedCalendarIDs: Set<String> = [] {
        didSet {
            save(selectedCalendarIDs, key: "selectedCalendarIDs")
        }
    }
    
    // MARK: - Upcoming Settings
    @Published var includeCalendarInUpcoming: Bool = true {
        didSet { save(includeCalendarInUpcoming, key: "includeCalendarInUpcoming") }
    }
    
    // Helper Enum for Time Limit selection in UI
    enum UpcomingTimeLimit: String, CaseIterable, Identifiable {
        case next3Days = "Next 3 Days"
        case next5Days = "Next 5 Days"
        case next7Days = "Next 7 Days"
        case allFuture = "All Future"
        
        var id: String { rawValue }
        
        // Helper to convert selection to simple Integer for math
        var days: Int? {
            switch self {
            case .next3Days: return 3
            case .next5Days: return 5
            case .next7Days: return 7
            case .allFuture: return nil
            }
        }
        
    }
    
    @Published var upcomingTimeLimit: UpcomingTimeLimit = .allFuture {
        didSet { save(upcomingTimeLimit.rawValue, key: "upcomingTimeLimit") }
    }
    
    @Published var groupUpcomingByDate: Bool = false {
        didSet { save(groupUpcomingByDate, key: "groupUpcomingByDate") }
    }
    
    // MARK: - Alerts Settings
    @Published var includeCalendarInAlerts: Bool = true {
        didSet { save(includeCalendarInAlerts, key: "includeCalendarInAlerts") }
    }
    
    enum AlertTiming: String, CaseIterable, Identifiable {
        case atStart = "At event start"
        case fiveMinBefore = "5 minutes before"
        case tenMinBefore = "10 minutes before"
        case fifteenMinBefore = "15 minutes before"
        
        var id: String { rawValue }
        
        var secondsBefore: TimeInterval {
            switch self {
            case .atStart: return 0
            case .fiveMinBefore: return 300
            case .tenMinBefore: return 600
            case .fifteenMinBefore: return 900
            }
        }
    }
    
    @Published var alertTiming: AlertTiming = .fiveMinBefore {
        didSet { save(alertTiming.rawValue, key: "alertTiming") }
    }
    
    enum AutoDismissInterval: String, CaseIterable, Identifiable {
        case fiveMin = "5 minutes"
        case tenMin = "10 minutes"
        case fifteenMin = "15 minutes"
        
        var id: String { rawValue }
        
        var seconds: TimeInterval {
            switch self {
            case .fiveMin: return 300
            case .tenMin: return 600
            case .fifteenMin: return 900
            }
        }
    }
    
    @Published var autoDismissAlerts: AutoDismissInterval = .tenMin {
        didSet { save(autoDismissAlerts.rawValue, key: "autoDismissAlerts") }
    }
    
    // MARK: - General Settings
    enum Tab: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case upcoming = "Upcoming"
        case notes = "Notes" // Assuming this is the 3rd tab (Resources)
        
        var id: String { rawValue }
    }
    
    @Published var defaultLaunchTab: Tab = .dashboard {
        didSet { save(defaultLaunchTab.rawValue, key: "defaultLaunchTab") }
    }
    
    // MARK: - Init & Persistence
    init() {
        // Load whatever settings we saved last time the app ran.
        loadSettings()
    }
    
    // Generic Helper to save any supported type to UserDefaults
    private func save(_ value: Any, key: String) {
        if let set = value as? Set<String> {
             // Sets typically can't be saved directly to Plist, so convert to Array
             UserDefaults.standard.set(Array(set), forKey: key)
        } else {
            UserDefaults.standard.set(value, forKey: key)
        }
    }
    
    // Restore all values
    private func loadSettings() {
        if let savedIDs = UserDefaults.standard.array(forKey: "selectedCalendarIDs") as? [String] {
            selectedCalendarIDs = Set(savedIDs)
        }
        
        if UserDefaults.standard.object(forKey: "includeCalendarInUpcoming") != nil {
            includeCalendarInUpcoming = UserDefaults.standard.bool(forKey: "includeCalendarInUpcoming")
        }
        
        if let limitRaw = UserDefaults.standard.string(forKey: "upcomingTimeLimit"),
           let limit = UpcomingTimeLimit(rawValue: limitRaw) {
            upcomingTimeLimit = limit
        }
        
        if UserDefaults.standard.object(forKey: "groupUpcomingByDate") != nil {
            groupUpcomingByDate = UserDefaults.standard.bool(forKey: "groupUpcomingByDate")
        }
        
        if UserDefaults.standard.object(forKey: "includeCalendarInAlerts") != nil {
            includeCalendarInAlerts = UserDefaults.standard.bool(forKey: "includeCalendarInAlerts")
        }
        
        if let timingRaw = UserDefaults.standard.string(forKey: "alertTiming"),
           let timing = AlertTiming(rawValue: timingRaw) {
            alertTiming = timing
        }
        
        if let dismissRaw = UserDefaults.standard.string(forKey: "autoDismissAlerts"),
           let dismiss = AutoDismissInterval(rawValue: dismissRaw) {
            autoDismissAlerts = dismiss
        }
        
        if let tabRaw = UserDefaults.standard.string(forKey: "defaultLaunchTab"),
           let tab = Tab(rawValue: tabRaw) {
            defaultLaunchTab = tab
        }
    }
}
