//
//  Color+Theme.swift
//  GymTrack Pro
//
//  Created by Claude Code on 27/01/26.
//

import SwiftUI

// MARK: - Theme Colors

extension Color {
    // MARK: - Background Colors

    /// Main app background - #0F172A
    static let gymBackground = Color(hex: 0x0F172A)

    /// Card/surface background - #1E293B
    static let gymCard = Color(hex: 0x1E293B)

    /// Hover/pressed state - #334155
    static let gymCardHover = Color(hex: 0x334155)

    // MARK: - Primary Colors

    /// Primary action color (Indigo) - #6366F1
    static let gymPrimary = Color(hex: 0x6366F1)

    /// Primary light variant - #818CF8
    static let gymPrimaryLight = Color(hex: 0x818CF8)

    // MARK: - Accent Colors

    /// Accent/highlight color (Cyan) - #22D3EE
    static let gymAccent = Color(hex: 0x22D3EE)

    // MARK: - Semantic Colors

    /// Success state (Green) - #10B981
    static let gymSuccess = Color(hex: 0x10B981)

    /// Warning state (Amber) - #F59E0B
    static let gymWarning = Color(hex: 0xF59E0B)

    /// Error state (Red) - #EF4444
    static let gymError = Color(hex: 0xEF4444)

    // MARK: - Text Colors

    /// Primary text (White) - #F8FAFC
    static let gymText = Color(hex: 0xF8FAFC)

    /// Secondary/muted text (Gray) - #94A3B8
    static let gymTextMuted = Color(hex: 0x94A3B8)

    // MARK: - Border Colors

    /// Border color - #334155
    static let gymBorder = Color(hex: 0x334155)

    // MARK: - Gradient

    /// Primary gradient for featured elements
    static let gymGradient = LinearGradient(
        colors: [gymPrimary, gymAccent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Success gradient for achievements
    static let gymSuccessGradient = LinearGradient(
        colors: [gymSuccess, Color(hex: 0x34D399)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Fire/streak gradient
    static let gymStreakGradient = LinearGradient(
        colors: [Color(hex: 0xF97316), Color(hex: 0xEF4444)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Hex Initializer

extension Color {
    /// Initialize a Color from a hex value
    /// - Parameter hex: The hex color value (e.g., 0x6366F1)
    init(hex: UInt) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }

    /// Initialize a Color from a hex string
    /// - Parameter hexString: The hex color string (e.g., "#6366F1" or "6366F1")
    init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (r, g, b) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }

        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}

// MARK: - Color Utilities

extension Color {
    /// Returns a slightly lighter version of the color
    func lighter(by percentage: Double = 0.1) -> Color {
        self.opacity(1 - percentage)
    }

    /// Returns a slightly darker version of the color
    func darker(by percentage: Double = 0.1) -> Color {
        // Blend with black
        self.opacity(1 - percentage)
    }
}
