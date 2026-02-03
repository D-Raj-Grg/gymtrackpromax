//
//  WorkoutDayCard.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

/// Card component displaying workout day info for split builder
struct WorkoutDayCard: View {
    // MARK: - Properties

    let day: DraftWorkoutDay
    let dayNumber: Int
    var onTap: (() -> Void)?
    var onDelete: (() -> Void)?
    var showDragHandle: Bool = true

    /// Number of distinct superset groups in this day
    private var supersetCount: Int {
        Set(day.exercises.compactMap { $0.supersetGroupId }).count
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: AppSpacing.component) {
            // Drag Handle
            if showDragHandle {
                Image(systemName: "line.3.horizontal")
                    .font(.body)
                    .foregroundStyle(Color.gymTextMuted)
                    .frame(width: 24)
            }

            // Day Number Badge
            ZStack {
                Circle()
                    .fill(Color.gymPrimary)
                    .frame(width: 36, height: 36)

                Text("\(dayNumber)")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gymText)
            }

            // Day Info
            VStack(alignment: .leading, spacing: 4) {
                Text(day.name.isEmpty ? "Day \(dayNumber)" : day.name)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.gymText)

                if day.exercises.isEmpty {
                    Text("No exercises added")
                        .font(.caption)
                        .foregroundStyle(Color.gymTextMuted)
                } else {
                    HStack(spacing: AppSpacing.small) {
                        // Exercise count
                        HStack(spacing: 4) {
                            Image(systemName: "dumbbell.fill")
                                .font(.caption2)
                            Text("\(day.exercises.count) exercise\(day.exercises.count == 1 ? "" : "s")")
                                .font(.caption)
                        }

                        Text("•")

                        // Total sets
                        HStack(spacing: 4) {
                            Image(systemName: "square.stack.fill")
                                .font(.caption2)
                            Text("\(day.totalSets) sets")
                                .font(.caption)
                        }

                        Text("•")

                        // Duration
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text("~\(day.estimatedDuration)min")
                                .font(.caption)
                        }
                    }
                    .foregroundStyle(Color.gymTextMuted)
                }

                // Superset indicator
                if supersetCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.caption2)
                        Text("\(supersetCount) superset\(supersetCount == 1 ? "" : "s")")
                            .font(.caption)
                    }
                    .foregroundStyle(Color.gymAccent)
                }

                // Exercise preview
                if !day.exercises.isEmpty {
                    Text(day.exercises.prefix(3).map { $0.exerciseName }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(Color.gymTextMuted)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Edit indicator
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)
        }
        .padding(AppSpacing.component)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.card)
                .fill(Color.gymCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.card)
                .strokeBorder(day.isValid ? Color.clear : Color.gymWarning.opacity(0.5), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap?()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(day.name.isEmpty ? "Day \(dayNumber)" : day.name), \(day.exercises.count) exercises")
        .accessibilityHint("Double tap to edit")
    }
}

/// Compact card for preview in lists
struct WorkoutDayCardCompact: View {
    // MARK: - Properties

    let day: DraftWorkoutDay
    let dayNumber: Int

    // MARK: - Body

    var body: some View {
        HStack(spacing: AppSpacing.component) {
            // Day Number Badge
            ZStack {
                Circle()
                    .fill(Color.gymPrimary.opacity(0.15))
                    .frame(width: 28, height: 28)

                Text("\(dayNumber)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gymPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(day.name.isEmpty ? "Day \(dayNumber)" : day.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.gymText)

                Text("\(day.exercises.count) exercises • \(day.totalSets) sets")
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview("With Exercises") {
    VStack(spacing: AppSpacing.component) {
        WorkoutDayCard(
            day: DraftWorkoutDay(
                name: "Push Day",
                dayOrder: 0,
                exercises: [
                    DraftPlannedExercise(
                        exerciseId: UUID(),
                        exerciseName: "Barbell Bench Press",
                        primaryMuscle: .chest,
                        targetSets: 4
                    ),
                    DraftPlannedExercise(
                        exerciseId: UUID(),
                        exerciseName: "Overhead Press",
                        primaryMuscle: .shoulders,
                        targetSets: 3
                    ),
                    DraftPlannedExercise(
                        exerciseId: UUID(),
                        exerciseName: "Tricep Pushdown",
                        primaryMuscle: .triceps,
                        targetSets: 3
                    )
                ]
            ),
            dayNumber: 1,
            onTap: { print("Tapped") },
            onDelete: { print("Delete") }
        )

        WorkoutDayCard(
            day: DraftWorkoutDay(
                name: "",
                dayOrder: 1,
                exercises: []
            ),
            dayNumber: 2,
            onTap: { print("Tapped") },
            onDelete: { print("Delete") }
        )
    }
    .padding()
    .background(Color.gymBackground)
}

#Preview("Compact") {
    VStack(spacing: AppSpacing.small) {
        WorkoutDayCardCompact(
            day: DraftWorkoutDay(
                name: "Push Day",
                dayOrder: 0,
                exercises: [
                    DraftPlannedExercise(
                        exerciseId: UUID(),
                        exerciseName: "Bench Press",
                        primaryMuscle: .chest,
                        targetSets: 4
                    )
                ]
            ),
            dayNumber: 1
        )

        WorkoutDayCardCompact(
            day: DraftWorkoutDay(
                name: "Pull Day",
                dayOrder: 1,
                exercises: []
            ),
            dayNumber: 2
        )
    }
    .padding()
    .background(Color.gymCard)
}
