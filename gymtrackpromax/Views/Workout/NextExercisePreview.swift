//
//  NextExercisePreview.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

struct NextExercisePreview: View {
    // MARK: - Properties

    let exercise: PlannedExercise?

    // MARK: - Body

    var body: some View {
        if let exercise = exercise {
            HStack(spacing: AppSpacing.component) {
                // Icon
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.gymPrimary.opacity(0.7))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Next")
                        .font(.caption)
                        .foregroundStyle(Color.gymTextMuted)

                    Text(exercise.exerciseName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.gymText)
                        .lineLimit(1)
                }

                Spacer()

                // Sets info
                Text(exercise.setsAndRepsDisplay)
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)
            }
            .padding(AppSpacing.component)
            .background(Color.gymCard.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.small))
        }
    }
}

// MARK: - Preview

#Preview {
    let exercise = PlannedExercise(
        exerciseOrder: 1,
        targetSets: 3,
        targetRepsMin: 10,
        targetRepsMax: 12,
        restSeconds: 90
    )

    NextExercisePreview(exercise: exercise)
        .padding()
        .background(Color.gymBackground)
}
