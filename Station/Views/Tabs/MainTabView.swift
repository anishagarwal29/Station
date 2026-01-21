import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Today", systemImage: "house.fill")
                }
                .tag(0)
            
            UpcomingView()
                .tabItem {
                    Label("Upcoming", systemImage: "calendar")
                }
                .tag(1)
            
            PlaceholderView(title: "Notes", icon: "note.text")
                .tabItem {
                    Label("Notes", systemImage: "pencil.and.outline")
                }
                .tag(2)
            
            PlaceholderView(title: "Settings", icon: "gearshape.fill")
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .accentColor(Theme.accentBlue)
        .background(Theme.background)
    }
}

struct PlaceholderView: View {
    let title: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(Theme.textSecondary.opacity(0.3))
            
            Text("\(title) Placeholder")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Theme.textSecondary)
            
            Text("This feature is coming soon.")
                .font(.system(size: 16))
                .foregroundColor(Theme.textSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
