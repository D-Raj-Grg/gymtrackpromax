//
//  MuscleBalanceView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 30/01/26.
//

import SwiftUI

/// Horizontal bar chart showing set distribution per muscle group
struct MuscleBalanceView: View {
    // MARK: - Properties

    let distribution: [MuscleDistribution]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            // Header
            HStack {
                Text("Muscle Balance")
                    .font(.headline)
                    .foregroundStyle(Color.gymText)

                Spacer()

                Text("by working sets")
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)
            }

            if distribution.isEmpty {
                Text("Complete workouts to see muscle distribution")
                    .font(.subheadline)
                    .foregroundStyle(Color.gymTextMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AppSpacing.standard)
            } else {
                VStack(spacing: AppSpacing.small) {
                    ForEach(distribution) { item in
                        muscleRow(item)
                    }
                }
            }
        }
        .padding(AppSpacing.card)
        .background(Color.gymCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
    }

    // MARK: - Muscle Row

    private func muscleRow(_ item: MuscleDistribution) -> some View {
        VStack(spacing: AppSpacing.xs) {
            HStack {
                Text(item.muscle.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.gymText)

                Spacer()

                Text("\(item.sets) sets")
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)

                Text("(\(Int(item.percentage))%)")
                    .font(.caption2)
                    .foregroundStyle(Color.gymTextMuted)
            }

            // Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gymBackground)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorForMuscle(item.muscle))
                        .frame(width: max(4, geometry.size.width * item.percentage / 100), height: 8)
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: - Color Mapping

    private func colorForMuscle(_ muscle: MuscleGroup) -> Color {
        switch muscle.bodyRegion {
        case .upper:
            return Color.gymPrimary
        case .lower:
            return Color.gymSuccess
        case .arms:
            return Color.gymAccent
        case .core:
            return Color.gymWarning
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gymBackground.ignoresSafeArea()

        MuscleBalanceView(distribution: [
            MuscleDistribution(muscle: .chest, sets: 15, percentage: 20),
            MuscleDistribution(muscle: .back, sets: 12, percentage: 16),
            MuscleDistribution(muscle: .shoulders, sets: 10, percentage: 13),
            MuscleDistribution(muscle: .quads, sets: 9, percentage: 12),
            MuscleDistribution(muscle: .biceps, sets: 8, percentage: 11),
            MuscleDistribution(muscle: .triceps, sets: 7, percentage: 9),
            MuscleDistribution(muscle: .hamstrings, sets: 6, percentage: 8),
            MuscleDistribution(muscle: .glutes, sets: 5, percentage: 7),
            MuscleDistribution(muscle: .calves, sets: 3, percentage: 4),
        ])
        .padding()
    }
}
