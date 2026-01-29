//
//  ExerciseListSheet.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

struct ExerciseListSheet: View {
    // MARK: - Properties

    let exerciseLogs: [ExerciseLog]
    let currentIndex: Int
    let onSelectExercise: (Int) -> Void
    let onDismiss: () -> Void

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.component) {
                        ForEach(Array(exerciseLogs.enumerated()), id: \.element.id) { index, log in
                            ExerciseListRow(
                                exerciseLog: log,
                                index: index,
                                isCurrent: index == currentIndex,
                                isCompleted: !log.sets.isEmpty
                            ) {
                                onSelectExercise(index)
                            }
                        }
                    }
                    .padding(AppSpacing.standard)
                }
            }
            .navigationTitle("Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundStyle(Color.gymPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Exercise List Row

struct ExerciseListRow: View {
    let exerciseLog: ExerciseLog
    let index: Int
    let isCurrent: Bool
    let isCompleted: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.component) {
                // Status indicator
                statusIndicator

                // Exercise info
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(exerciseLog.exerciseName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.gymText)
                        .lineLimit(1)

                    // Muscle group
                    if let muscle = exerciseLog.exercise?.primaryMuscle {
                        Text(muscle.displayName)
                            .font(.caption)
                            .foregroundStyle(Color.gymTextMuted)
                    }
                }

                Spacer()

                // Sets completed
                if isCompleted {
                    Text("\(exerciseLog.workingSets) sets")
                        .font(.caption)
                        .foregroundStyle(Color.gymSuccess)
                }

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)
            }
            .padding(AppSpacing.standard)
            .background(isCurrent ? Color.gymPrimary.opacity(0.15) : Color.gymCard)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .stroke(isCurrent ? Color.gymPrimary : Color.clear, lineWidth: 2)
            )
        }
    }

    private var statusIndicator: some View {
        ZStack {
            Circle()
                .fill(statusColor.opacity(0.2))
                .frame(width: 36, height: 36)

            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gymSuccess)
            } else if isCurrent {
                Circle()
                    .fill(Color.gymPrimary)
                    .frame(width: 12, height: 12)
            } else {
                Text("\(index + 1)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.gymTextMuted)
            }
        }
    }

    private var statusColor: Color {
        if isCompleted {
            return Color.gymSuccess
        } else if isCurrent {
            return Color.gymPrimary
        }
        return Color.gymCardHover
    }
}

// MARK: - Preview

#Preview {
    let log1 = ExerciseLog(exerciseOrder: 0)
    let log2 = ExerciseLog(exerciseOrder: 1)
    let log3 = ExerciseLog(exerciseOrder: 2)

    // Add some sets to first log
    let set = SetLog(setNumber: 1, weight: 80, reps: 10)
    set.exerciseLog = log1
    log1.sets = [set]

    return ExerciseListSheet(
        exerciseLogs: [log1, log2, log3],
        currentIndex: 1,
        onSelectExercise: { _ in },
        onDismiss: {}
    )
}
