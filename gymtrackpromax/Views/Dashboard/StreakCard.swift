//
//  StreakCard.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

struct StreakCard: View {
    // MARK: - Properties

    let streakCount: Int

    // MARK: - Body

    var body: some View {
        HStack(spacing: AppSpacing.standard) {
            // Fire icon
            Image(systemName: "flame.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.white)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                // Streak count
                Text("\(streakCount)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.white)
                +
                Text(" day streak")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.white.opacity(0.9))

                // Motivational text
                Text(motivationalText)
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.8))
            }

            Spacer()
        }
        .padding(AppSpacing.card)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.cardLarge)
                .fill(Color.gymStreakGradient)
        )
        .accessibleCard(label: streakCount == 1 ? "\(streakCount) day streak. \(motivationalText)" : "\(streakCount) day streak. \(motivationalText)")
    }

    // MARK: - Computed Properties

    private var motivationalText: String {
        if streakCount == 0 {
            return "Start your streak today!"
        } else if streakCount == 1 {
            return "Great start! Keep it going!"
        } else if streakCount < 7 {
            return "Keep it going!"
        } else if streakCount < 14 {
            return "You're on fire!"
        } else if streakCount < 30 {
            return "Incredible dedication!"
        } else {
            return "Unstoppable!"
        }
    }
}

// MARK: - Preview

#Preview("Active Streak") {
    VStack(spacing: AppSpacing.standard) {
        StreakCard(streakCount: 7)
        StreakCard(streakCount: 1)
        StreakCard(streakCount: 0)
    }
    .padding()
    .background(Color.gymBackground)
}
