/*
 Station > Views > Dashboard > DashboardView.swift
 -------------------------------------------------
 PURPOSE:
 The "Home Screen" of the app. It gives an at-a-glance summary of everything important happening NOW.
 
 LAYOUT STRATEGY:
 - Composed of "Blocks" (Widgets) rather than standard lists.
 - Uses a ScrollView to accommodate small screens, but designed to look like a fixed dashboard on large screens.
 */

import SwiftUI

struct DashboardView: View {
    var body: some View {
        HStack(spacing: 0) {
            // Main Content Area
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 1. Header: Date & Status
                    HeaderView()
                    
                    // 2. Alerts: Urgent items taking full width
                    AlertsBlock()
                    
                    // 3. Main Grid: Split into Left (Classes) and Right (Upcoming/Notes)
                    HStack(alignment: .top, spacing: 24) {
                        // Left Column: Today's Schedule (Takes available space)
                        VStack(alignment: .leading, spacing: 24) {
                            ClassesBlock()
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Right Column: Fixed width sidebar for secondary info
                        VStack(alignment: .leading, spacing: 24) {
                            UpcomingBlock()
                            QuickNotesBlock()
                            PinnedResourcesBlock()
                        }
                        .frame(maxWidth: 400) // Fixed width sidebar
                    }
                }
                .padding(32)
            }
        }
        .background(Theme.background)
        .foregroundColor(Theme.textPrimary)
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
