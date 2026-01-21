import SwiftUI

struct HeaderView: View {
    @StateObject private var dateManager = DateManager()
    
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
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    
                    Text("IN SESSION")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.green)
                }
            }
        }
    }
}
