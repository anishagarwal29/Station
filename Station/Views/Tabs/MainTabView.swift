/*
 Station > Views > Tabs > MainTabView.swift
 ------------------------------------------
 PURPOSE:
 The Root View of the application. It creates the navigation structure.
 
 DESIGN:
 - Instead of the standard macOS TabView (which puts tabs at the top), 
   we implement a custom "ZStack + Floating Bar" design.
   This places the content in the back and a floating capsule bar at the bottom.
 */

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    // We update the 'selectedTab' on launch based on user preference
    @ObservedObject var settings = SettingsManager.shared
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // LAYER 1: Main Content Area
            // We use standard swift 'if/else' switching. 
            // This ensures only one view is active at a time.
            Group {
                if selectedTab == 0 { DashboardView() }
                else if selectedTab == 1 { UpcomingView() }
                else if selectedTab == 2 { ResourcesView() }
                else if selectedTab == 3 { SettingsView() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Add padding so content isn't hidden behind the floating bar
            .padding(.bottom, 80)
            
            // LAYER 2: Custom Floating Tab Bar
            HStack(spacing: 4) {
                // Tab 1: Dashboard (Blue)
                TabButton(
                    icon: "square.grid.2x2.fill",
                    title: "Dashboard",
                    color: Theme.accentBlue,
                    isSelected: selectedTab == 0
                ) { selectedTab = 0 }
                
                // Tab 2: Upcoming (Purple)
                TabButton(
                    icon: "calendar",
                    title: "Upcoming",
                    color: Color(hex: "A56EFF"), // Custom Violet
                    isSelected: selectedTab == 1
                ) { selectedTab = 1 }
                
                // Tab 3: Resources (Orange)
                TabButton(
                    icon: "folder.fill",
                    title: "Resources",
                    color: Color(hex: "FF9F0A"), // Apple SF Orange
                    isSelected: selectedTab == 2
                ) { selectedTab = 2 }
                
                // Tab 4: Settings (Slate/Gray)
                TabButton(
                    icon: "gearshape.fill",
                    title: "Settings",
                    color: Color(hex: "8E8E93"), // System Gray
                    isSelected: selectedTab == 3
                ) { selectedTab = 3 }
            }
            .padding(6)
            // Glassmorphism Strategy:
            // 1. Black opacity for darkness
            // 2. ultraThinMaterial for the blur effect
            // 3. White stroke for the 'glass edge' look
            .background(Color.black.opacity(0.4))
            .background(.ultraThinMaterial)
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
            // Restore last session's tab or user preference
            switch settings.defaultLaunchTab {
            case .dashboard: selectedTab = 0
            case .upcoming: selectedTab = 1
            case .notes: selectedTab = 2
            }
        }
    }
}

// CUSTOM COMPONENT: TabButton
// Handles the animation and coloring logic for a single tab.
struct TabButton: View {
    let icon: String
    let title: String
    let color: Color // Now accepts a unique color per tab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                
                // We only show text when selected (Dynamic Expansion)
                if isSelected {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            // Color Logic: Use the passed 'color' if selected, otherwise clear background
            .background(isSelected ? color : Color.clear)
            .foregroundColor(isSelected ? .white : Theme.textSecondary)
            .clipShape(Capsule())
            .contentShape(Capsule())
            // Spring Animation for that "bouncy" feel
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

// Preview Provider for Xcode Canvas
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
