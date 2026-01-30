//
//  TodayWorkoutView.swift
//  GymTrackProWidgets
//
//  Created by Claude Code on 30/01/26.
//

import SwiftUI
import WidgetKit

/// Widget view for today's workout. Supports small and medium sizes.
struct TodayWorkoutView: View {
    let entry: TodayWorkoutEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallView
            case .systemMedium:
                mediumView
            default:
                smallView
            }
        }
        .containerBackground(for: .widget) {
            Color.gymCard
        }
    }

    // MARK: - Small View

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if entry.isRestDay {
                restDaySmall
            } else {
                workoutDaySmall
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(4)
    }

    private var restDaySmall: some View {
        VStack(spacing: 8) {
            Image(systemName: "bed.double.fill")
                .font(.system(size: 28))
                .foregroundStyle(Color.gymAccent)

            Text("Rest Day")
                .font(.headline)
                .foregroundStyle(Color.gymText)

            Text("Recover & grow")
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var workoutDaySmall: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack {
                Image(systemName: "dumbbell.fill")
                    .font(.caption)
                    .foregroundStyle(Color.gymPrimary)
                Text("TODAY")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.gymPrimary)
            }

            // Workout name
            Text(entry.workoutName ?? "Workout")
                .font(.headline)
                .foregroundStyle(Color.gymText)
                .lineLimit(2)

            Spacer()

            // Muscle group pills (max 2)
            HStack(spacing: 4) {
                ForEach(entry.muscleGroups.prefix(2), id: \.self) { muscle in
                    Text(muscle)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color.gymPrimaryLight)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gymPrimary.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Medium View

    private var mediumView: some View {
        HStack(spacing: 16) {
            if entry.isRestDay {
                restDayMedium
            } else {
                workoutDayMedium
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(4)
    }

    private var restDayMedium: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: "bed.double.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.gymAccent)

            VStack(alignment: .leading, spacing: 4) {
                Text("Rest Day")
                    .font(.title3.bold())
                    .foregroundStyle(Color.gymText)

                Text("Take it easy. Your muscles are recovering and growing stronger.")
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var workoutDayMedium: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header row
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "dumbbell.fill")
                        .font(.caption)
                        .foregroundStyle(Color.gymPrimary)
                    Text("TODAY'S WORKOUT")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.gymPrimary)
                }

                Spacer()

                // Duration estimate
                HStack(spacing: 2) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text("~\(entry.estimatedDuration)m")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(Color.gymTextMuted)
            }

            // Workout name
            Text(entry.workoutName ?? "Workout")
                .font(.title3.bold())
                .foregroundStyle(Color.gymText)
                .lineLimit(1)

            Spacer()

            // Bottom row: muscle groups + exercise count
            HStack {
                // Muscle group pills
                HStack(spacing: 4) {
                    ForEach(entry.muscleGroups.prefix(3), id: \.self) { muscle in
                        Text(muscle)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.gymPrimaryLight)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.gymPrimary.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                // Exercise count
                Text("\(entry.exerciseCount) exercises")
                    .font(.caption2)
                    .foregroundStyle(Color.gymTextMuted)
            }
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    TodayWorkoutWidget()
} timeline: {
    TodayWorkoutEntry(date: .now, workoutName: "Push Day", muscleGroups: ["Chest", "Shoulders", "Triceps"], exerciseCount: 6, estimatedDuration: 55, isRestDay: false)
    TodayWorkoutEntry(date: .now, workoutName: nil, muscleGroups: [], exerciseCount: 0, estimatedDuration: 0, isRestDay: true)
}

#Preview(as: .systemMedium) {
    TodayWorkoutWidget()
} timeline: {
    TodayWorkoutEntry(date: .now, workoutName: "Push Day", muscleGroups: ["Chest", "Shoulders", "Triceps"], exerciseCount: 6, estimatedDuration: 55, isRestDay: false)
    TodayWorkoutEntry(date: .now, workoutName: nil, muscleGroups: [], exerciseCount: 0, estimatedDuration: 0, isRestDay: true)
}
