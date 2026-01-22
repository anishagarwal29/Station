import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @ObservedObject var settings = SettingsManager.shared
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content Area
            Group {
                if selectedTab == 0 { DashboardView() }
                else if selectedTab == 1 { UpcomingView() }
                else if selectedTab == 2 { ResourcesView() }
                else if selectedTab == 3 { SettingsView() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Add padding so content isn't hidden behind the floating bar
            .padding(.bottom, 80)
            
            // Custom Floating Tab Bar
            HStack(spacing: 4) {
                TabButton(icon: "square.grid.2x2.fill", title: "Dashboard", isSelected: selectedTab == 0) { selectedTab = 0 }
                TabButton(icon: "calendar", title: "Upcoming", isSelected: selectedTab == 1) { selectedTab = 1 }
                TabButton(icon: "folder.fill", title: "Resources", isSelected: selectedTab == 2) { selectedTab = 2 }
                TabButton(icon: "gearshape.fill", title: "Settings", isSelected: selectedTab == 3) { selectedTab = 3 }
            }
            .padding(6)
            .background(Color.black.opacity(0.4)) // Darker backing
            .background(.ultraThinMaterial) // Glassy effect
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
            .padding(.bottom, 24)
        }
        .background(Theme.background)
        .onAppear {
            switch settings.defaultLaunchTab {
            case .dashboard: selectedTab = 0
            case .upcoming: selectedTab = 1
            case .notes: selectedTab = 2
            }
        }
    }
}

struct TabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                
                if isSelected {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Theme.accentBlue : Color.clear)
            .foregroundColor(isSelected ? .white : Theme.textSecondary)
            .clipShape(Capsule())
            // Smooth animation for selection expansion
            .contentShape(Capsule())
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
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
