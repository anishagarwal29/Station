import Foundation
import Combine

class DateManager: ObservableObject {
    @Published var currentDay: String = ""
    @Published var currentWeek: String = ""
    
    private var timer: AnyCancellable?
    
    init() {
        updateDate()
        // Update at midnight or periodically to handle day changes
        timer = Timer.publish(every: 3600, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateDate()
            }
    }
    
    func updateDate() {
        let now = Date()
        let calendar = Calendar.current
        
        // Format Day (e.g., TUESDAY)
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        currentDay = dayFormatter.string(from: now).uppercased()
        
        // Compute Week Number
        // We'll use the ISO week number or standard calendar week
        let weekNumber = calendar.component(.weekOfYear, from: now)
        currentWeek = "WEEK \(weekNumber)"
    }
}
