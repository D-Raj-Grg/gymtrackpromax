//
//  WorkoutLockScreenView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 30/01/26.
//

import SwiftUI
import WidgetKit

struct WorkoutLockScreenView: View {
    let attributes: WorkoutActivityAttributes
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        VStack(spacing: 8) {
            // Top: Workout name + elapsed time
            HStack {
                Label(attributes.workoutName, systemImage: "dumbbell.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.caption)
                    Text(attributes.startTime, style: .timer)
                        .font(.subheadline.monospacedDigit())
                }
                .foregroundStyle(.secondary)
            }

            Divider()
                .overlay(Color.white.opacity(0.15))

            // Middle: Exercise info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Exercise \(state.currentExerciseNumber)/\(attributes.totalExercises)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(state.currentExerciseName)
                        .font(.headline)
                        .foregroundStyle(.white)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(state.currentMuscleGroup)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.cyan.opacity(0.3))
                        .clipShape(Capsule())

                    Text("\(state.setsCompleted)/\(state.targetSets) sets")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                }
            }

            Divider()
                .overlay(Color.white.opacity(0.15))

            // Bottom: Rest timer or total sets
            HStack {
                if state.isResting,
                   let start = state.restTimerStart,
                   let end = state.restTimerEnd {
                    Label {
                        Text(timerInterval: start...end, countsDown: true)
                            .font(.subheadline.monospacedDigit().weight(.semibold))
                    } icon: {
                        Image(systemName: "hourglass")
                    }
                    .foregroundStyle(.cyan)

                    Spacer()

                    Text("Resting")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Label("\(state.totalSetsLogged) sets logged", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.green)

                    Spacer()
                }
            }
        }
        .padding(16)
    }
}
