//
//  StreakView.swift
//  GymTrackProWidgets
//
//  Created by Claude Code on 30/01/26.
//

import SwiftUI
import WidgetKit

/// Small widget view displaying the current workout streak.
struct StreakView: View {
    let entry: StreakEntry

    var body: some View {
        VStack(spacing: 4) {
            // Flame icon
            Image(systemName: entry.streakCount > 0 ? "flame.fill" : "flame")
                .font(.system(size: 32))
                .foregroundStyle(entry.streakCount > 0 ? Color.orange : Color.gymTextMuted)

            // Streak number
            Text("\(entry.streakCount)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(Color.gymText)

            // Label
            Text(entry.streakCount == 1 ? "Day Streak" : "Day Streak")
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)

            // Motivational text
            Text(motivationalText)
                .font(.system(size: 10))
                .foregroundStyle(Color.gymTextMuted)
                .multilineTextAlignment(.center)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            if entry.streakCount > 0 {
                LinearGradient(
                    colors: [
                        Color(hex: 0xEA580C).opacity(0.8),
                        Color(hex: 0xDC2626).opacity(0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(Color.gymBackground.opacity(0.3))
            } else {
                Color.gymCard
            }
        }
    }

    private var motivationalText: String {
        switch entry.streakCount {
        case 0:
            return "Start today!"
        case 1...2:
            return "Keep it up!"
        case 3...6:
            return "On fire!"
        case 7...13:
            return "Unstoppable!"
        case 14...29:
            return "Beast mode!"
        default:
            return "Legendary!"
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    StreakWidget()
} timeline: {
    StreakEntry(date: .now, streakCount: 0)
    StreakEntry(date: .now, streakCount: 7)
    StreakEntry(date: .now, streakCount: 30)
}
