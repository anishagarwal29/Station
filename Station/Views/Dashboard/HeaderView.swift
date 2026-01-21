import SwiftUI

struct HeaderView: View {
    @StateObject private var dateManager = DateManager()
    @EnvironmentObject var calendarManager: CalendarManager
    
    private var schoolStatus: (text: String, color: Color) {
        let now = Date()
        let calendar = Calendar.current
        
        // Filter for today's events only
        let todaysEvents = calendarManager.events.filter { calendar.isDateInToday($0.startDate) }
        
        if todaysEvents.isEmpty {
            return ("INACTIVE", .gray)
        }
        
        // Check if currently in session
        let isInSession = todaysEvents.contains { event in
            now >= event.startDate && now <= event.endDate
        }
        
        if isInSession {
            return ("IN SESSION", .green)
        }
        
        // Check if school is over (all events have ended)
        let isSchoolOver = todaysEvents.allSatisfy { event in
            now > event.endDate
        }
        
        if isSchoolOver {
            return ("SCHOOL OVER", .gray)
        }
        
        // If has classes today, not in session, and not over -> Break
        return ("BREAK", .yellow)
    }
    
    var body: some View {
        HStack {
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
