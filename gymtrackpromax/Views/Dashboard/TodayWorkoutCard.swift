//
//  TodayWorkoutCard.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI
import Foundation
import SwiftData

struct TodayWorkoutCard: View {
    // MARK: - Properties

    let workoutDay: WorkoutDay?
    let onStartWorkout: () -> Void
    var onAddExercises: (() -> Void)? = nil

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.standard) {
            // Header
            HStack {
                Text("Today's Workout")
                    .font(.headline)
                    .foregroundStyle(Color.gymText)

                Spacer()

                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(Color.gymTextMuted)
            }

            if let workout = workoutDay {
                workoutContent(workout)
            } else {
                restDayContent
            }
        }
        .padding(AppSpacing.card)
        .background(Color.gymCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.cardLarge))
    }

    // MARK: - Workout Content

    @ViewBuilder
    private func workoutContent(_ workout: WorkoutDay) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            // Workout name
            Text(workout.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.gymText)

            // Muscle group chips
            if !workout.primaryMuscles.isEmpty {
                muscleChips(workout.primaryMuscles)
            }

            // Stats row
            HStack(spacing: AppSpacing.section) {
                statItem(
                    icon: "dumbbell.fill",
                    value: "\(workout.exerciseCount)",
                    label: "exercises"
                )

                statItem(
                    icon: "clock.fill",
                    value: "~\(workout.estimatedDuration)",
                    label: "min"
                )

                statItem(
                    icon: "flame.fill",
                    value: "\(workout.totalSets)",
                    label: "sets"
                )
            }

            // Start workout or add exercises button
            if workout.exerciseCount > 0 {
                Button {
                    HapticManager.mediumImpact()
                    onStartWorkout()
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Workout")
                    }
                }
                .primaryButtonStyle()
                .padding(.top, AppSpacing.small)
                .accessibleButton(label: "Start \(workout.name) workout", hint: "Double tap to begin your workout")
            } else {
                VStack(spacing: AppSpacing.small) {
                    Text("No exercises added yet")
                        .font(.subheadline)
                        .foregroundStyle(Color.gymTextMuted)

                    Button {
                        HapticManager.buttonTap()
                        onAddExercises?()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Exercises")
                        }
                    }
                    .secondaryButtonStyle()
                }
                .padding(.top, AppSpacing.small)
            }
        }
    }

    // MARK: - Rest Day Content

    private var restDayContent: some View {
        VStack(spacing: AppSpacing.component) {
            Image(systemName: "bed.double.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.gymSuccess)

            Text("Rest Day")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.gymText)

            Text("Recovery is just as important as training. Take it easy today!")
                .font(.subheadline)
                .foregroundStyle(Color.gymTextMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.standard)
    }

    // MARK: - Subviews

    private func muscleChips(_ muscles: [MuscleGroup]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.small) {
                ForEach(muscles, id: \.self) { muscle in
                    Text(muscle.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.gymText)
                        .padding(.horizontal, AppSpacing.component)
                        .padding(.vertical, AppSpacing.xs)
                        .background(Color.gymCardHover)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.gymPrimary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.gymText)

            Text(label)
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)
        }
    }

    // MARK: - Helpers

    private var formattedDate: String {
        let formatter = Foundation.DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }
}

// MARK: - Preview

#Preview("With Workout") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutDay.self, configurations: config)

    let workoutDay = WorkoutDay(name: "Push Day", dayOrder: 0, scheduledWeekdays: [1, 4])

    TodayWorkoutCard(workoutDay: workoutDay) {
        print("Start workout tapped")
    }
    .padding()
    .background(Color.gymBackground)
}

#Preview("Rest Day") {
    TodayWorkoutCard(workoutDay: nil) {
        print("Start workout tapped")
    }
    .padding()
    .background(Color.gymBackground)
}
