import SwiftUI

struct UpcomingBlock: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Upcoming")
                .font(.system(size: 20, weight: .bold))
            
            HStack(spacing: 12) {
                UpcomingCard(
                    day: "WEDNESDAY",
                    title: "History Essay",
                    detail: "Submission Due"
                )
                
                UpcomingCard(
                    day: "THURSDAY",
                    title: "Basketball",
                    detail: "Tryouts @ 16:00"
                )
            }
        }
    }
}

struct UpcomingCard: View {
    let day: String
    let title: String
    let detail: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(day)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Theme.accentBlue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(Theme.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
