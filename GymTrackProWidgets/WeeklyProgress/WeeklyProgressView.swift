//
//  WeeklyProgressView.swift
//  GymTrackProWidgets
//
//  Created by Claude Code on 30/01/26.
//

import SwiftUI
import WidgetKit

/// Medium widget view showing weekly workout stats.
struct WeeklyProgressView: View {
    let entry: WeeklyProgressEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.caption)
                    .foregroundStyle(Color.gymAccent)
                Text("THIS WEEK")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.gymAccent)
                Spacer()
            }

            Spacer()

            // Stats row — 3 columns
            HStack(spacing: 0) {
                statColumn(
                    value: "\(entry.workoutCount)",
                    label: "Workouts",
                    color: Color.gymPrimary
                )

                divider

                statColumn(
                    value: formattedVolume,
                    label: "Volume (\(entry.weightUnitSymbol))",
                    color: Color.gymAccent
                )

                divider

                statColumn(
                    value: "\(entry.prCount)",
                    label: "PRs",
                    color: Color.gymSuccess
                )
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(4)
        .containerBackground(for: .widget) {
            Color.gymCard
        }
    }

    // MARK: - Subviews

    private func statColumn(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Color.gymTextMuted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.gymBorder)
            .frame(width: 1, height: 30)
    }

    // MARK: - Formatting

    private var formattedVolume: String {
        if entry.totalVolume >= 10000 {
            return String(format: "%.1fk", entry.totalVolume / 1000)
        } else if entry.totalVolume >= 1000 {
            return String(format: "%.1fk", entry.totalVolume / 1000)
        } else {
            return String(format: "%.0f", entry.totalVolume)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    WeeklyProgressWidget()
} timeline: {
    WeeklyProgressEntry(date: .now, workoutCount: 4, totalVolume: 12500, prCount: 2, weightUnitSymbol: "kg")
    WeeklyProgressEntry(date: .now, workoutCount: 0, totalVolume: 0, prCount: 0, weightUnitSymbol: "kg")
}
