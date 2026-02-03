//
//  RecentPRsCard.swift
//  GymTrack Pro
//
//  Created by Claude Code on 30/01/26.
//

import SwiftUI

/// Card displaying recent personal records on the dashboard
struct RecentPRsCard: View {
    // MARK: - Properties

    let recentPRs: [DashboardPRInfo]
    let weightUnit: WeightUnit

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            // Header
            HStack(spacing: AppSpacing.small) {
                Image(systemName: "trophy.fill")
                    .font(.title3)
                    .foregroundStyle(Color.gymWarning)
                    .accessibilityHidden(true)

                Text("Recent PRs")
                    .font(.headline)
                    .foregroundStyle(Color.gymText)

                Spacer()
            }

            if recentPRs.isEmpty {
                // Empty state
                HStack {
                    Spacer()
                    VStack(spacing: AppSpacing.small) {
                        Text("No PRs this week")
                            .font(.subheadline)
                            .foregroundStyle(Color.gymTextMuted)
                        Text("Keep pushing - your next PR is coming!")
                            .font(.caption)
                            .foregroundStyle(Color.gymTextMuted.opacity(0.7))
                    }
                    Spacer()
                }
                .padding(.vertical, AppSpacing.small)
            } else {
                // PR list
                VStack(spacing: AppSpacing.small) {
                    ForEach(recentPRs) { pr in
                        prRow(pr)
                    }
                }
            }
        }
        .padding(AppSpacing.card)
        .background(Color.gymCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
    }

    // MARK: - Subviews

    private func prRow(_ pr: DashboardPRInfo) -> some View {
        HStack(spacing: AppSpacing.component) {
            // Trophy icon
            Image(systemName: "star.fill")
                .font(.caption)
                .foregroundStyle(Color.gymWarning)
                .accessibilityHidden(true)

            // Exercise name
            Text(pr.exerciseName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.gymText)
                .lineLimit(1)

            Spacer()

            // Weight x Reps
            Text(formatSet(weight: pr.weight, reps: pr.reps))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.gymText)

            // 1RM
            Text("1RM: \(formatWeight(pr.estimated1RM))")
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)
        }
        .padding(.vertical, AppSpacing.xs)
    }

    // MARK: - Formatting

    private func formatSet(weight: Double, reps: Int) -> String {
        let weightStr = weight.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(weight))"
            : String(format: "%.1f", weight)
        return "\(weightStr) \(weightUnit.symbol) x \(reps)"
    }

    private func formatWeight(_ weight: Double) -> String {
        let weightStr = weight.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(weight))"
            : String(format: "%.1f", weight)
        return "\(weightStr) \(weightUnit.symbol)"
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gymBackground.ignoresSafeArea()

        VStack(spacing: AppSpacing.standard) {
            RecentPRsCard(
                recentPRs: [
                    DashboardPRInfo(exerciseName: "Bench Press", weight: 100, reps: 5, estimated1RM: 116.7, date: Date()),
                    DashboardPRInfo(exerciseName: "Squat", weight: 140, reps: 3, estimated1RM: 154, date: Date()),
                    DashboardPRInfo(exerciseName: "Deadlift", weight: 180, reps: 1, estimated1RM: 180, date: Date()),
                ],
                weightUnit: .kg
            )

            RecentPRsCard(
                recentPRs: [],
                weightUnit: .kg
            )
        }
        .padding()
    }
}
