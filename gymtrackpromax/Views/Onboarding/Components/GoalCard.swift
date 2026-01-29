//
//  GoalCard.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

/// Selectable card for fitness goal selection
struct GoalCard: View {
    let goal: FitnessGoal
    let isSelected: Bool
    let onTap: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppSpacing.component) {
                // Icon with circle background
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.gymPrimary.opacity(0.2) : Color.gymCardHover)
                        .frame(width: 56, height: 56)

                    Image(systemName: goal.iconName)
                        .font(.system(size: 24))
                        .foregroundStyle(isSelected ? Color.gymPrimary : Color.gymText)
                }

                // Title
                Text(goal.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.gymText)
                    .multilineTextAlignment(.center)

                // Description
                Text(goal.description)
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 160)
            .padding(AppSpacing.standard)
            .background(Color.gymCard)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .stroke(isSelected ? Color.gymPrimary : Color.gymBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gymBackground.ignoresSafeArea()
        HStack(spacing: AppSpacing.component) {
            GoalCard(goal: .buildMuscle, isSelected: true, onTap: {})
            GoalCard(goal: .getStronger, isSelected: false, onTap: {})
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
