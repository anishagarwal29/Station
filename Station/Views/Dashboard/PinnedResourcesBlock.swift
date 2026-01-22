/*
 Station > Views > Dashboard > PinnedResourcesBlock.swift
 --------------------------------------------------------
 PURPOSE:
 Displays a horizontal row of "Pinned" resources for quick access.
 
 LOGIC:
 - Filters resources where `isPinned == true`.
 - Clicking a circle opens the URL.
 */

import SwiftUI

struct PinnedResourcesBlock: View {
    @EnvironmentObject var resourceManager: ResourceManager
    
    var body: some View {
        let pinnedItems = resourceManager.items.filter { $0.isPinned }
        
        if !pinnedItems.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("PINNED")
                    .font(.system(size: 20, weight: .bold)) // Match other headers
                    .foregroundColor(Theme.textPrimary)
                    .tracking(0) // Reset tracking
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(pinnedItems) { item in
                            Button(action: {
                                if let url = item.url {
                                    openURL(url)
                                }
                            }) {
                                VStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(Theme.cardBackground)
                                            .frame(width: 48, height: 48)
                                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                                        
                                        Image(systemName: item.iconName)
                                            .font(.system(size: 20))
                                            .foregroundColor(Theme.accentBlue)
                                    }
                                    
                                    Text(item.title)
                                        .font(.caption)
                                        .foregroundColor(Theme.textSecondary)
                                        .lineLimit(1)
                                        .frame(width: 60) // Constrain width for alignment
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 8) // Space for shadow
                }
            }
        }
    }
    
    // Helper to open URL using NSWorkspace
    private func openURL(_ url: URL) {
        NSWorkspace.shared.open(url)
    }
}
