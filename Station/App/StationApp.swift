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
                .onOpenURL { url in
                    // 1. Check if the link is meant for adding a resource
                    guard url.scheme == "station" && url.host == "add-resource" else { return }
                    
                    // 2. Extract the data from the link
                    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                    let title = components?.queryItems?.first(where: { $0.name == "title" })?.value ?? "New Idea"
                    let targetUrl = components?.queryItems?.first(where: { $0.name == "url" })?.value ?? ""
                    let tagsString = components?.queryItems?.first(where: { $0.name == "tags" })?.value ?? ""
                    let icon = components?.queryItems?.first(where: { $0.name == "icon" })?.value ?? "link"
                    
                    let tags = tagsString.split(separator: ",").map { String($0) }
                    
                    // 3. Silent Add: Directly Add to Library
                    resourceManager.addItem(
                        title: title,
                        urlString: targetUrl,
                        tags: tags,
                        iconName: icon
                    )
                    
                    // 4. Force Navigation to Resources Tab
                    resourceManager.shouldNavigateToResources = true
                    
                    print("Forge Bridge: Silent Added \(title)")
                }
        }
        // Removes the standard gray title bar for a custom, full-content look.
        .windowStyle(.hiddenTitleBar)
        // SINGLE WINDOW: Force reuse of existing window for deep links
        .handlesExternalEvents(matching: ["*"])
    }
}
