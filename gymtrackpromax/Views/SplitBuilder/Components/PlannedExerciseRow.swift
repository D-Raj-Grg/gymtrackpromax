//
//  PlannedExerciseRow.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

/// Row component displaying a planned exercise with sets/reps
struct PlannedExerciseRow: View {
    // MARK: - Properties

    let exercise: DraftPlannedExercise
    var onTap: (() -> Void)?
    var onDelete: (() -> Void)?
    var showDragHandle: Bool = true
    var isEditable: Bool = true
    var leadingAccessory: AnyView? = nil

    // MARK: - Body

    var body: some View {
        HStack(spacing: AppSpacing.component) {
            // Drag Handle / Leading Accessory
            if let accessory = leadingAccessory {
                accessory
            } else if showDragHandle {
                Image(systemName: "line.3.horizontal")
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)
                    .frame(width: 20)
            }

            // Exercise Info
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.exerciseName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.gymText)
                    .lineLimit(1)

                HStack(spacing: AppSpacing.small) {
                    // Sets x Reps
                    HStack(spacing: 4) {
                        Image(systemName: "square.stack.fill")
                            .font(.caption2)
                        Text(exercise.setsAndRepsDisplay)
                            .font(.caption)
                    }
                    .foregroundStyle(Color.gymTextMuted)

                    Text("•")
                        .foregroundStyle(Color.gymTextMuted)

                    // Rest Time
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.caption2)
                        Text(formatRestTime(exercise.restSeconds))
                            .font(.caption)
                    }
                    .foregroundStyle(Color.gymTextMuted)

                    // Muscle badge
                    Text(exercise.primaryMuscle.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.gymPrimary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.gymPrimary.opacity(0.15))
                        )
                }
            }

            Spacer()

            if isEditable {
                // Edit indicator
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)
            }
        }
        .padding(AppSpacing.component)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.card)
                .fill(Color.gymCard)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if isEditable {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onTap?()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exercise.exerciseName), \(exercise.setsAndRepsDisplay)")
        .accessibilityHint(isEditable ? "Double tap to edit" : "")
    }

    // MARK: - Helpers

    private func formatRestTime(_ seconds: Int) -> String {
        if seconds >= 60 {
            let minutes = seconds / 60
            let secs = seconds % 60
            if secs == 0 {
                return "\(minutes)m"
            }
            return "\(minutes)m \(secs)s"
        }
        return "\(seconds)s"
    }
}

/// Compact version of the exercise row for lists
struct PlannedExerciseRowCompact: View {
    // MARK: - Properties

    let exercise: DraftPlannedExercise

    // MARK: - Body

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Circle()
                .fill(Color.gymPrimary.opacity(0.2))
                .frame(width: 8, height: 8)

            Text(exercise.exerciseName)
                .font(.subheadline)
                .foregroundStyle(Color.gymText)
                .lineLimit(1)

            Spacer()

            Text("\(exercise.targetSets)x\(exercise.targetRepsMin)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.gymTextMuted)
        }
    }
}

// MARK: - Preview

#Preview("Standard") {
    VStack(spacing: AppSpacing.component) {
        PlannedExerciseRow(
            exercise: DraftPlannedExercise(
                exerciseId: UUID(),
                exerciseName: "Barbell Bench Press",
                primaryMuscle: .chest,
                targetSets: 4,
                targetRepsMin: 6,
                targetRepsMax: 8,
                restSeconds: 180
            ),
            onTap: { print("Tapped") },
            onDelete: { print("Delete") }
        )

        PlannedExerciseRow(
            exercise: DraftPlannedExercise(
                exerciseId: UUID(),
                exerciseName: "Incline Dumbbell Press",
                primaryMuscle: .chest,
                targetSets: 3,
                targetRepsMin: 8,
                targetRepsMax: 12,
                restSeconds: 90
            ),
            onTap: { print("Tapped") },
            onDelete: { print("Delete") }
        )
    }
    .padding()
    .background(Color.gymBackground)
}

#Preview("Compact") {
    VStack(spacing: AppSpacing.small) {
        PlannedExerciseRowCompact(
            exercise: DraftPlannedExercise(
                exerciseId: UUID(),
                exerciseName: "Barbell Bench Press",
                primaryMuscle: .chest
            )
        )

        PlannedExerciseRowCompact(
            exercise: DraftPlannedExercise(
                exerciseId: UUID(),
                exerciseName: "Incline Dumbbell Press",
                primaryMuscle: .chest
            )
        )
    }
    .padding()
    .background(Color.gymCard)
}
