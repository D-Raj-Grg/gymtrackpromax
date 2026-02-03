//
//  WatchSetInputView.swift
//  GymTrackProWatch
//
//  Set input view with Digital Crown support.
//

import SwiftUI
import WatchKit

/// Input view for logging sets with Digital Crown support
struct WatchSetInputView: View {
    @EnvironmentObject var viewModel: WatchWorkoutViewModel
    let exercise: ExerciseStateDTO

    var body: some View {
        VStack(spacing: 8) {
            // Weight/Reps display with focus toggle
            HStack(spacing: 12) {
                // Weight
                weightInput

                // Reps
                repsInput
            }

            // Digital Crown indicator
            HStack(spacing: 4) {
                Image(systemName: "digitalcrown.horizontal.arrow.clockwise")
                    .font(.caption2)
                Text(viewModel.inputFocus == .weight ? "Adjust weight" : "Adjust reps")
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)

            // Options row
            HStack {
                // Warmup toggle
                Button(action: viewModel.toggleWarmup) {
                    HStack(spacing: 2) {
                        Image(systemName: viewModel.setInput.isWarmup ? "checkmark.circle.fill" : "circle")
                            .font(.caption2)
                        Text("Warmup")
                            .font(.caption2)
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(viewModel.setInput.isWarmup ? .orange : .secondary)

                Spacer()
            }

            // Log button
            Button(action: {
                #if targetEnvironment(simulator)
                if viewModel.isSimulatorMockMode {
                    viewModel.logMockSet()
                } else {
                    viewModel.logSet()
                }
                #else
                viewModel.logSet()
                #endif
            }) {
                Text("Log Set")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .focusable()
        .digitalCrownRotation(
            viewModel.inputFocus == .weight
                ? Binding(
                    get: { viewModel.setInput.weight },
                    set: { viewModel.setInput.weight = max(0, $0) }
                )
                : Binding(
                    get: { Double(viewModel.setInput.reps) },
                    set: { viewModel.setInput.reps = max(1, Int($0)) }
                ),
            from: 0,
            through: viewModel.inputFocus == .weight ? 500 : 100,
            by: viewModel.inputFocus == .weight ? 0.5 : 1,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
    }

    // MARK: - Weight Input

    private var weightInput: some View {
        VStack(spacing: 2) {
            Text("Weight")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Button(action: {
                viewModel.inputFocus = .weight
            }) {
                Text(formatWeight(viewModel.setInput.weight))
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .foregroundStyle(viewModel.inputFocus == .weight ? .blue : .primary)
            }
            .buttonStyle(.plain)

            // Stepper buttons
            HStack(spacing: 8) {
                Button(action: viewModel.decrementWeight) {
                    Image(systemName: "minus.circle.fill")
                        .font(.caption)
                }
                .buttonStyle(.plain)

                Button(action: viewModel.incrementWeight) {
                    Image(systemName: "plus.circle.fill")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Reps Input

    private var repsInput: some View {
        VStack(spacing: 2) {
            Text("Reps")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Button(action: {
                viewModel.inputFocus = .reps
            }) {
                Text("\(viewModel.setInput.reps)")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .foregroundStyle(viewModel.inputFocus == .reps ? .blue : .primary)
            }
            .buttonStyle(.plain)

            // Stepper buttons
            HStack(spacing: 8) {
                Button(action: viewModel.decrementReps) {
                    Image(systemName: "minus.circle.fill")
                        .font(.caption)
                }
                .buttonStyle(.plain)

                Button(action: viewModel.incrementReps) {
                    Image(systemName: "plus.circle.fill")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func formatWeight(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(weight))"
        }
        return String(format: "%.1f", weight)
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
        completedSets: [],
        suggestedWeight: 60,
        suggestedReps: 10
    )

    return WatchSetInputView(exercise: exercise)
        .environmentObject(WatchWorkoutViewModel())
}
