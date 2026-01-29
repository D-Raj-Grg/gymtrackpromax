//
//  ExerciseProgressCard.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI
import Charts

struct ExerciseProgressCard: View {
    // MARK: - Properties

    let exerciseProgress: ExerciseProgress
    let weightUnit: WeightUnit
    let onTap: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.component) {
                // Header
                headerSection

                // Estimated 1RM
                oneRMSection

                // Sparkline
                if !exerciseProgress.recentDataPoints.isEmpty {
                    sparklineSection
                }

                // Stats row
                statsRow
            }
            .padding(AppSpacing.card)
            .frame(width: 200)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .fill(Color.gymCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .stroke(Color.gymBorder.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(exerciseProgress.exercise.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.gymText)
                .lineLimit(1)

            HStack(spacing: AppSpacing.xs) {
                Image(systemName: exerciseProgress.exercise.primaryMuscle.iconName)
                    .font(.caption2)
                    .foregroundStyle(Color.gymPrimary)

                Text(exerciseProgress.exercise.primaryMuscle.displayName)
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)
            }
        }
    }

    // MARK: - 1RM Section

    private var oneRMSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Est. 1RM")
                .font(.caption2)
                .foregroundStyle(Color.gymTextMuted)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(formatWeight(exerciseProgress.estimated1RM))
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gymText)

                Text(weightUnit.symbol)
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)
            }
        }
    }

    // MARK: - Sparkline Section

    private var sparklineSection: some View {
        Chart(exerciseProgress.recentDataPoints) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("1RM", point.estimated1RM)
            )
            .foregroundStyle(Color.gymAccent)
            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
            .interpolationMethod(.catmullRom)

            AreaMark(
                x: .value("Date", point.date),
                y: .value("1RM", point.estimated1RM)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color.gymAccent.opacity(0.3),
                        Color.gymAccent.opacity(0.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .frame(height: 40)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack {
            // Best weight
            VStack(alignment: .leading, spacing: 2) {
                Text("Best")
                    .font(.caption2)
                    .foregroundStyle(Color.gymTextMuted)

                Text("\(formatWeight(exerciseProgress.bestWeight)) x \(exerciseProgress.bestReps)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.gymText)
            }

            Spacer()

            // Total sets
            VStack(alignment: .trailing, spacing: 2) {
                Text("Sets")
                    .font(.caption2)
                    .foregroundStyle(Color.gymTextMuted)

                Text("\(exerciseProgress.totalSets)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.gymText)
            }
        }
    }

    // MARK: - Formatting

    private func formatWeight(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(weight))"
        }
        return String(format: "%.1f", weight)
    }
}

// MARK: - Preview

#Preview {
    let exercise = Exercise(
        name: "Bench Press",
        primaryMuscle: .chest,
        secondaryMuscles: [.triceps, .shoulders],
        equipment: .barbell
    )

    let dataPoints = [
        ExerciseProgress.DataPoint(date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!, estimated1RM: 85),
        ExerciseProgress.DataPoint(date: Calendar.current.date(byAdding: .day, value: -8, to: Date())!, estimated1RM: 87.5),
        ExerciseProgress.DataPoint(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, estimated1RM: 90),
        ExerciseProgress.DataPoint(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, estimated1RM: 92.5),
        ExerciseProgress.DataPoint(date: Date(), estimated1RM: 95)
    ]

    let progress = ExerciseProgress(
        exercise: exercise,
        estimated1RM: 100,
        bestWeight: 90,
        bestReps: 5,
        totalSets: 45,
        recentDataPoints: dataPoints
    )

    return ExerciseProgressCard(
        exerciseProgress: progress,
        weightUnit: .kg
    ) {
        print("Tapped")
    }
    .padding()
    .background(Color.gymBackground)
}
