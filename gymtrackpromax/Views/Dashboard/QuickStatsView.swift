//
//  QuickStatsView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

struct QuickStatsView: View {
    // MARK: - Properties

    let workoutsThisWeek: Int
    let volumeThisWeek: String
    let prsThisWeek: Int
    let weightUnit: WeightUnit

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            // Header
            Text("This Week")
                .font(.headline)
                .foregroundStyle(Color.gymText)

            // Stats row
            HStack(spacing: AppSpacing.component) {
                statCard(
                    value: "\(workoutsThisWeek)",
                    label: "Workouts",
                    icon: "figure.run"
                )

                statCard(
                    value: volumeThisWeek,
                    label: "Volume (\(weightUnit.symbol))",
                    icon: "scalemass.fill"
                )

                statCard(
                    value: "\(prsThisWeek)",
                    label: "PRs",
                    icon: "trophy.fill"
                )
            }
        }
    }

    // MARK: - Subviews

    private func statCard(value: String, label: String, icon: String) -> some View {
        VStack(spacing: AppSpacing.small) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.gymPrimary)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.gymText)
                .monospacedDigit()

            Text(label)
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.standard)
        .background(Color.gymCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
        .accessibleCard(label: "\(value) \(label)")
    }
}

// MARK: - Preview

#Preview {
    VStack {
        QuickStatsView(
            workoutsThisWeek: 4,
            volumeThisWeek: "12.5k",
            prsThisWeek: 2,
            weightUnit: .kg
        )

        QuickStatsView(
            workoutsThisWeek: 0,
            volumeThisWeek: "0",
            prsThisWeek: 0,
            weightUnit: .lbs
        )
    }
    .padding()
    .background(Color.gymBackground)
}
