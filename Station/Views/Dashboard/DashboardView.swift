import SwiftUI

struct DashboardView: View {
    var body: some View {
        HStack(spacing: 0) {
            // Main Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HeaderView()
                    
                    AlertsBlock()
                    
                    HStack(alignment: .top, spacing: 24) {
                        VStack(alignment: .leading, spacing: 24) {
                            ClassesBlock()
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack(alignment: .leading, spacing: 24) {
                            UpcomingBlock()
                            QuickNotesBlock()
                        }
                        .frame(maxWidth: 400)
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
