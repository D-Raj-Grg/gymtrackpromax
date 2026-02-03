//
//  WatchExerciseView.swift
//  GymTrackProWatch
//
//  View for displaying current exercise details and logging sets.
//

import SwiftUI
import WatchKit

/// View for a single exercise during a workout
struct WatchExerciseView: View {
    @EnvironmentObject var viewModel: WatchWorkoutViewModel
    let exercise: ExerciseStateDTO

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                // Exercise header
                exerciseHeader

                // Progress indicator
                progressSection

                Divider()

                // Set input
                WatchSetInputView(exercise: exercise)
                    .environmentObject(viewModel)

                // Completed sets
                if !exercise.completedSets.isEmpty {
                    completedSetsSection
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Exercise Header

    private var exerciseHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Superset indicator
            if exercise.isInSuperset, let position = exercise.supersetPosition {
                HStack(spacing: 4) {
                    Image(systemName: "link")
                        .font(.caption2)
                    Text("Superset \(position)")
                        .font(.caption2)
                }
                .foregroundStyle(.orange)
            }

            // Exercise name
            Text(exercise.exerciseName)
                .font(.headline)
                .lineLimit(2)

            // Muscle group
            Text(exercise.muscleGroup)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        HStack {
            // Sets progress
            Text("\(exercise.completedSets.count)/\(exercise.targetSets)")
                .font(.caption)
                .foregroundStyle(.blue)

            Text("sets")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Spacer()

            // Previous best
            if let previous = exercise.previousBest {
                Text("Last: \(previous)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Completed Sets Section

    private var completedSetsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Completed")
                .font(.caption2)
                .foregroundStyle(.secondary)

            ForEach(exercise.completedSets, id: \.setId) { set in
                HStack {
                    // Set number
                    Text("\(set.setNumber)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 16)

                    // Weight x Reps
                    Text(set.display)
                        .font(.caption)

                    Spacer()

                    // PR badge
                    if set.isPR {
                        Image(systemName: "trophy.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }

                    // Warmup indicator
                    if set.isWarmup {
                        Text("W")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let exercise = ExerciseStateDTO(
        exerciseLogId: "1",
        exerciseName: "Bench Press",
        muscleGroup: "Chest",
        targetSets: 4,
        targetRepsMin: 8,
        targetRepsMax: 12,
        completedSets: [
            SetDTO(setId: "1", setNumber: 1, weight: 60, reps: 10),
            SetDTO(setId: "2", setNumber: 2, weight: 60, reps: 9)
        ],
        suggestedWeight: 60,
        suggestedReps: 10,
        previousBest: "60 × 10"
    )

    return WatchExerciseView(exercise: exercise)
        .environmentObject(WatchWorkoutViewModel())
}
