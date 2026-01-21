import SwiftUI

@main
struct StationApp: App {
    @StateObject private var upcomingManager = UpcomingManager()
    @StateObject private var calendarManager = CalendarManager()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .frame(minWidth: 1000, minHeight: 700)
                .background(Theme.background)
                .environmentObject(upcomingManager)
                .environmentObject(calendarManager)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
