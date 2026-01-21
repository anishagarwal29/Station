import SwiftUI

struct Theme {
    static let background = Color(hex: "0B121E")
    static let cardBackground = Color(hex: "151D29")
    static let alertBackground = Color(hex: "0D2137")
    static let accentBlue = Color(hex: "2187FF")
    static let textSecondary = Color.gray
    static let textPrimary = Color.white
    static let urgentColor = Color.orange // Or red based on preference, mockup shows blue icon/text for urgent? Wait, mockup says "URGENT" in blue/white.
    
    static let cornerRadius: CGFloat = 12
    static let padding: CGFloat = 16
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
