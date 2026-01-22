/*
 Station > Core > Theme.swift
 ----------------------------
 PURPOSE:
 This file acts as the "Design System" for the entire app.
 Instead of hardcoding colors like Color.red or hex codes in every view, we define them here ONCE.
 This makes it easy to change the app's "Vibe" later by just editing this one file.
 */

import SwiftUI

struct Theme {
    // Static Constants: Accessible anywhere as `Theme.background` without creating an instance.
    static let background = Color(hex: "0B121E")    // Deep Navy/Black
    static let cardBackground = Color(hex: "151D29") // Slightly lighter for Cards
    static let alertBackground = Color(hex: "0D2137") // Specific background for Alerts
    static let accentBlue = Color(hex: "2187FF")    // The main Brand color
    
    static let textSecondary = Color.gray
    static let textPrimary = Color.white
    static let urgentColor = Color.orange
    
    static let cornerRadius: CGFloat = 12
    static let padding: CGFloat = 16
}

/*
 EXTENSION: Color(hex:)
 ----------------------
 Swift doesn't have a built-in way to create colors from Hex Strings (like "#FFFFFF").
 This extension teaches the standard Color struct how to understand them.
 */
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
