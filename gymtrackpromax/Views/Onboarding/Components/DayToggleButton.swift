//
//  DayToggleButton.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

/// Circular toggle button for weekday selection
struct DayToggleButton: View {
    let dayLetter: String
    let isSelected: Bool
    let onTap: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            Text(dayLetter)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? Color.gymText : Color.gymTextMuted)
                .frame(width: 40, height: 40)
                .background(isSelected ? Color.gymPrimary : Color.gymCard)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.gymPrimary : Color.gymBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Weekday Helper

enum Weekday: Int, CaseIterable {
    case sunday = 0
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6

    var letter: String {
        switch self {
        case .sunday: return "S"
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "T"
        case .friday: return "F"
        case .saturday: return "S"
        }
    }

    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    var fullName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gymBackground.ignoresSafeArea()
        HStack(spacing: AppSpacing.small) {
            DayToggleButton(dayLetter: "M", isSelected: true, onTap: {})
            DayToggleButton(dayLetter: "T", isSelected: true, onTap: {})
            DayToggleButton(dayLetter: "W", isSelected: false, onTap: {})
            DayToggleButton(dayLetter: "T", isSelected: true, onTap: {})
            DayToggleButton(dayLetter: "F", isSelected: true, onTap: {})
            DayToggleButton(dayLetter: "S", isSelected: false, onTap: {})
            DayToggleButton(dayLetter: "S", isSelected: false, onTap: {})
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
