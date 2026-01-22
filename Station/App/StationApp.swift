/*
 Station > App > StationApp.swift
 --------------------------------
 PURPOSE:
 This is the specific "Entry Point" of your macOS Application.
 When you double-click the app icon, this is the first code that runs.
 
 RESPONSIBILITIES:
 1. Window Management: Defines the main window using `WindowGroup`.
 2. Dependency Injection: Creates the core "Managers" (Brains) of the app and passes them down.
 */

import SwiftUI

@main
struct StationApp: App {
    // @StateObject: These correspond to the "Singular Source of Truth" for your app's data.
    // By creating them here, they live for the entire lifetime of the app.
    @StateObject private var upcomingManager = UpcomingManager()
    @StateObject private var calendarManager = CalendarManager()
    @StateObject private var resourceManager = ResourceManager()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                // Window constraints ensure the specific "Dashboard" layout doesn't break.
                .frame(minWidth: 1000, minHeight: 700)
                .background(Theme.background)
                // ENVIRONMENT INJECTION:
                // Making these objects available to ANY child view that asks for them.
                .environmentObject(upcomingManager)
                .environmentObject(calendarManager)
                .environmentObject(resourceManager)
        }
        // Removes the standard gray title bar for a custom, full-content look.
        .windowStyle(.hiddenTitleBar)
    }
}
