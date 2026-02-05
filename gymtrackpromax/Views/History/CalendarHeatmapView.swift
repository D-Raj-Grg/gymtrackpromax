//
//  CalendarHeatmapView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

/// Calendar heatmap showing workout days with intensity coloring
struct CalendarHeatmapView: View {
    // MARK: - Properties

    let month: Date
    let selectedDate: Date?
    let weekStartDay: WeekStartDay
    let intensityForDate: (Date) -> Double
    let onDateTapped: (Date) -> Void

    // MARK: - Private Properties

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    private var weekdaySymbols: [String] {
        weekStartDay.orderedWeekdaySymbols
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: AppSpacing.component) {
            // Weekday headers
            weekdayHeader

            // Calendar grid
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { index, date in
                    CalendarDayCell(
                        date: date,
                        intensity: date != nil ? intensityForDate(date!) : 0,
                        isSelected: isSelected(date),
                        isToday: isToday(date),
                        onTap: {
                            if let date = date {
                                onDateTapped(date)
                            }
                        }
                    )
                }
            }
        }
        .padding(AppSpacing.standard)
        .background(Color.gymCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
        .accessibilityLabel("Workout calendar for \(monthYearLabel)")
    }

    // MARK: - Subviews

    private var weekdayHeader: some View {
        HStack(spacing: 4) {
            ForEach(orderedFullWeekdayNames.indices, id: \.self) { index in
                Text(weekdaySymbols[index])
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.gymTextMuted)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel(orderedFullWeekdayNames[index])
            }
        }
    }

    private var monthYearLabel: String {
        month.formatted(.dateTime.month(.wide).year())
    }

    private var orderedFullWeekdayNames: [String] {
        let allNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        switch weekStartDay {
        case .sunday:
            return allNames
        case .monday:
            return Array(allNames[1...]) + [allNames[0]]
        }
    }

    // MARK: - Computed Properties

    /// Generate array of dates for the month, with nil for padding
    private var daysInMonth: [Date?] {
        let calendar = Calendar.current

        // Get first day of month
        guard let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            return []
        }

        // Get range of days in month
        guard let range = calendar.range(of: .day, in: .month, for: month) else {
            return []
        }

        // Get weekday of first day (1 = Sunday, 2 = Monday, ... 7 = Saturday)
        let firstWeekdayRaw = calendar.component(.weekday, from: firstOfMonth)

        // Calculate leading padding based on week start preference
        let leadingPadding: Int
        switch weekStartDay {
        case .sunday:
            // Sunday = 1, so offset is (weekday - 1)
            leadingPadding = firstWeekdayRaw - 1
        case .monday:
            // Monday = 2, so offset is (weekday - 2), wrapping Sunday (1) to 6
            leadingPadding = (firstWeekdayRaw + 5) % 7
        }

        // Build array with leading padding
        var days: [Date?] = Array(repeating: nil, count: leadingPadding)

        // Add all days of the month
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }

        // Add trailing padding to complete the grid
        let remainder = days.count % 7
        if remainder > 0 {
            days.append(contentsOf: Array(repeating: nil, count: 7 - remainder))
        }

        return days
    }

    private func isSelected(_ date: Date?) -> Bool {
        guard let date = date, let selectedDate = selectedDate else { return false }
        let calendar = Calendar.current
        return calendar.isDate(date, inSameDayAs: selectedDate)
    }

    private func isToday(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        let calendar = Calendar.current
        return calendar.isDateInToday(date)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gymBackground.ignoresSafeArea()

        CalendarHeatmapView(
            month: Date(),
            selectedDate: nil,
            weekStartDay: .sunday,
            intensityForDate: { date in
                // Random intensity for preview
                let day = Calendar.current.component(.day, from: date)
                if day % 3 == 0 { return 0.8 }
                if day % 5 == 0 { return 0.5 }
                if day % 7 == 0 { return 0.3 }
                return 0
            },
            onDateTapped: { _ in }
        )
        .padding()
    }
}
