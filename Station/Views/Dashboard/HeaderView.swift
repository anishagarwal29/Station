/*
 Station > Views > Dashboard > HeaderView.swift
 ----------------------------------------------
 PURPOSE:
 Displays the current Date and the user's "Status" (e.g. "IN SESSION", "BREAK").
 
 LOGIC:
 - Derives status dynamically from the CalendarManager events.
 - "Smart" logic determines if you are currently in a class using Date refreshing.
 */

import SwiftUI

struct HeaderView: View {
    // Helper to get day/week strings
    @StateObject private var dateManager = DateManager()
    
    // We observe the calendar to update status if events change
    @EnvironmentObject var calendarManager: CalendarManager
    
    // COMPUTED PROPERTY: School Status
    // Returns a Tuple: (Text to show, Color to use).
    private var schoolStatus: (text: String, color: Color) {
        let now = Date()
        let calendar = Calendar.current
        
        // 1. Get Today's Classes
        let todaysEvents = calendarManager.events.filter { calendar.isDateInToday($0.startDate) }
        
        if todaysEvents.isEmpty {
            return ("INACTIVE", .gray)
        }
        
        // 2. Are we inside a class right now?
        let isInSession = todaysEvents.contains { event in
            now >= event.startDate && now <= event.endDate
        }
        
        if isInSession {
            return ("IN SESSION", .green)
        }
        
        // 3. Is school completely done?
        let isSchoolOver = todaysEvents.allSatisfy { event in
            now > event.endDate
        }
        
        if isSchoolOver {
            return ("SCHOOL OVER", .gray)
        }
        
        // 4. If has classes, not in one, and not over -> It's a Break/Passing period.
        return ("BREAK", .yellow)
    }
    
    var body: some View {
        HStack {
            // App Identity
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Theme.accentBlue)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "square.grid.2x2.fill")
                            .foregroundColor(.white)
                    )
                
                Text("Station")
                    .font(.system(size: 24, weight: .bold))
            }
            
            Spacer()
            
            // Date & Status Indicator
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(dateManager.currentDay), \(dateManager.currentWeek)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.textSecondary)
                
                let status = schoolStatus
                HStack(spacing: 6) {
                    Circle()
                        .fill(status.color)
                        .frame(width: 8, height: 8)
                    
                    Text(status.text)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(status.color)
                }
            }
        }
    }
}
