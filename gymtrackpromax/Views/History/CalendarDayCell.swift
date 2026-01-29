//
//  CalendarDayCell.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

/// Individual day cell for the calendar heatmap
struct CalendarDayCell: View {
    // MARK: - Properties

    let date: Date?
    let intensity: Double // 0-1, 0 means no workout
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void

    // MARK: - Private Properties

    private let cellSize: CGFloat = 36

    // MARK: - Body

    var body: some View {
        Button(action: {
            guard date != nil else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        }) {
            ZStack {
                // Background based on intensity
                if let _ = date {
                    RoundedRectangle(cornerRadius: AppCornerRadius.small)
                        .fill(backgroundFill)

                    // Selected border
                    if isSelected {
                        RoundedRectangle(cornerRadius: AppCornerRadius.small)
                            .strokeBorder(Color.gymPrimary, lineWidth: 2)
                    }

                    // Today indicator (subtle ring)
                    if isToday && !isSelected {
                        RoundedRectangle(cornerRadius: AppCornerRadius.small)
                            .strokeBorder(Color.gymAccent, lineWidth: 1.5)
                    }

                    // Day number
                    Text(dayText)
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(isToday ? .bold : .medium)
                        .foregroundStyle(textColor)
                }
            }
            .frame(width: cellSize, height: cellSize)
        }
        .buttonStyle(.plain)
        .disabled(date == nil)
    }

    // MARK: - Computed Properties

    private var dayText: String {
        guard let date = date else { return "" }
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        return "\(day)"
    }

    private var backgroundFill: Color {
        if intensity > 0 {
            // Workout day - show intensity with gymPrimary
            return Color.gymPrimary.opacity(intensity)
        } else {
            // No workout - transparent or very subtle
            return Color.clear
        }
    }

    private var textColor: Color {
        if intensity > 0.5 {
            // High intensity - use white text for contrast
            return Color.white
        } else if intensity > 0 {
            // Some workout - still use primary text
            return Color.gymText
        } else if isToday {
            // Today without workout
            return Color.gymAccent
        } else {
            // Regular day
            return Color.gymTextMuted
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gymBackground.ignoresSafeArea()

        HStack(spacing: AppSpacing.small) {
            // No workout
            CalendarDayCell(
                date: Date(),
                intensity: 0,
                isSelected: false,
                isToday: false,
                onTap: {}
            )

            // Light workout
            CalendarDayCell(
                date: Date(),
                intensity: 0.3,
                isSelected: false,
                isToday: false,
                onTap: {}
            )

            // Medium workout
            CalendarDayCell(
                date: Date(),
                intensity: 0.6,
                isSelected: false,
                isToday: false,
                onTap: {}
            )

            // Heavy workout
            CalendarDayCell(
                date: Date(),
                intensity: 1.0,
                isSelected: false,
                isToday: false,
                onTap: {}
            )

            // Today
            CalendarDayCell(
                date: Date(),
                intensity: 0,
                isSelected: false,
                isToday: true,
                onTap: {}
            )

            // Selected
            CalendarDayCell(
                date: Date(),
                intensity: 0.5,
                isSelected: true,
                isToday: false,
                onTap: {}
            )
        }
    }
}
