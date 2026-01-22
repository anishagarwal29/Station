/*
 Station > Views > Shared > StationEmptyState.swift
 --------------------------------------------------
 PURPOSE:
 A consistent, professional "Empty State" view to be used across the app
 when lists (Alerts, Classes, Resources) are empty.
 
 DESIGN:
 - Centered Icon (SF Symbol) with low opacity (0.3).
 - Muted Message text.
 */

import SwiftUI

struct StationEmptyState: View {
    let icon: String
    let message: String
    var includeBackground: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundColor(Theme.textSecondary.opacity(0.2)) // Lower opacity
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Take full space for centering
        .padding(.vertical, 40)
        .padding(.horizontal, 24)
        .background(
            includeBackground ?
            Theme.cardBackground.opacity(0.5) :
                Color.clear
        )
        .cornerRadius(Theme.cornerRadius)
    }
}

