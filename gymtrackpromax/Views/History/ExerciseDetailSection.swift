//
//  ExerciseDetailSection.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

/// Section displaying exercise details with all sets
struct ExerciseDetailSection: View {
    // MARK: - Properties

    let exerciseLog: ExerciseLog
    let weightUnit: WeightUnit

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            // Header
            headerView

            // Sets list
            setsListView

            // Exercise volume
            volumeView
        }
        .padding(AppSpacing.standard)
        .background(Color.gymCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack(alignment: .center, spacing: AppSpacing.small) {
            // Exercise name
            Text(exerciseLog.exerciseName)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.gymText)

            // Muscle group badge
            if let exercise = exerciseLog.exercise {
                muscleBadge(for: exercise.primaryMuscle)
            }

            Spacer()
        }
    }

    private func muscleBadge(for muscle: MuscleGroup) -> some View {
        Text(muscle.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(Color.gymPrimary)
            .padding(.horizontal, AppSpacing.small)
            .padding(.vertical, 4)
            .background(Color.gymPrimary.opacity(0.15))
            .clipShape(Capsule())
    }

    private var setsListView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            ForEach(exerciseLog.sortedSets) { set in
                setRow(set)
            }
        }
    }

    private func setRow(_ set: SetLog) -> some View {
        HStack(spacing: AppSpacing.small) {
            // Set number with indicator
            HStack(spacing: 4) {
                if set.isWarmup {
                    Text("W")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.gymWarning)
                } else if set.isDropset {
                    Text("D")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.gymAccent)
                } else {
                    Text("Set \(set.setNumber)")
                        .font(.subheadline)
                        .foregroundStyle(Color.gymTextMuted)
                }
            }
            .frame(width: 50, alignment: .leading)

            // Weight and reps
            Text(setDisplayString(set))
                .font(.system(.subheadline, design: .monospaced))
                .fontWeight(.medium)
                .foregroundStyle(Color.gymText)

            Spacer()

            // RPE if present
            if let rpe = set.rpe {
                Text("@\(rpe)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.gymTextMuted)
            }
        }
        .padding(.vertical, 4)
    }

    private var volumeView: some View {
        HStack {
            Spacer()
            Text("Volume: \(formattedVolume) \(weightUnit.symbol)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.gymTextMuted)
        }
        .padding(.top, AppSpacing.xs)
    }

    // MARK: - Formatting

    private func setDisplayString(_ set: SetLog) -> String {
        let weightStr: String
        if set.weight.truncatingRemainder(dividingBy: 1) == 0 {
            weightStr = "\(Int(set.weight))"
        } else {
            weightStr = String(format: "%.1f", set.weight)
        }
        return "\(weightStr) \(weightUnit.symbol) x \(set.reps) reps"
    }

    private var formattedVolume: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: exerciseLog.totalVolume)) ?? "0"
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gymBackground.ignoresSafeArea()

        VStack(spacing: AppSpacing.component) {
            // Sample exercise log
            ExerciseDetailSection(
                exerciseLog: {
                    let log = ExerciseLog(exerciseOrder: 0)
                    // Note: In real use, exercise and sets would be set via SwiftData relationships
                    return log
                }(),
                weightUnit: .kg
            )
        }
        .padding()
    }
}
