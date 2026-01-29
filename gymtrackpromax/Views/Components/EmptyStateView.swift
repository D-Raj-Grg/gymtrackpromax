//
//  EmptyStateView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

/// Reusable empty state component for displaying when there's no data
struct EmptyStateView: View {
    // MARK: - Properties

    /// SF Symbol icon name
    let icon: String

    /// Title text
    let title: String

    /// Description/message text
    let message: String

    /// Optional action button title
    var actionTitle: String? = nil

    /// Optional action callback
    var action: (() -> Void)? = nil

    /// Optional icon color (defaults to gymTextMuted)
    var iconColor: Color = .gymTextMuted

    /// Optional icon size
    var iconSize: CGFloat = 48

    // MARK: - Body

    var body: some View {
        VStack(spacing: AppSpacing.component) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: iconSize))
                .foregroundStyle(iconColor)
                .accessibilityHidden(true)

            // Title
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.gymText)
                .multilineTextAlignment(.center)

            // Message
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.gymTextMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.standard)

            // Optional action button
            if let actionTitle = actionTitle, let action = action {
                Button(action: {
                    HapticManager.buttonTap()
                    action()
                }) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.gymPrimary)
                }
                .padding(.top, AppSpacing.small)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.card)
                .fill(Color.gymCard)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}

// MARK: - Convenience Initializers

extension EmptyStateView {
    /// Create an empty state for no workouts
    static func noWorkouts(action: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "calendar.badge.exclamationmark",
            title: "No Workouts Yet",
            message: "Complete your first workout to see it here.",
            actionTitle: action != nil ? "Start Workout" : nil,
            action: action
        )
    }

    /// Create an empty state for no history
    static func noHistory() -> EmptyStateView {
        EmptyStateView(
            icon: "clock.arrow.circlepath",
            title: "No History",
            message: "Your completed workouts will appear here.",
            iconColor: .gymTextMuted
        )
    }

    /// Create an empty state for no PRs
    static func noPRs() -> EmptyStateView {
        EmptyStateView(
            icon: "trophy",
            title: "No PRs Yet",
            message: "Keep training to set your first personal record!",
            iconColor: .gymWarning
        )
    }

    /// Create an empty state for no exercises
    static func noExercises(action: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "dumbbell",
            title: "No Exercises",
            message: "Add exercises to your workout to get started.",
            actionTitle: action != nil ? "Add Exercise" : nil,
            action: action
        )
    }

    /// Create an empty state for search results
    static func noSearchResults() -> EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results",
            message: "Try adjusting your search or filters.",
            iconSize: 40
        )
    }

    /// Create an empty state for no progress data
    static func noProgress() -> EmptyStateView {
        EmptyStateView(
            icon: "chart.line.uptrend.xyaxis",
            title: "No Progress Data Yet",
            message: "Complete your first workout to start tracking your progress.",
            iconColor: .gymPrimary
        )
    }
}

// MARK: - Preview

#Preview("Default") {
    EmptyStateView(
        icon: "calendar.badge.exclamationmark",
        title: "No Workouts Yet",
        message: "Complete your first workout to see it here.",
        actionTitle: "Start Workout",
        action: { print("Action tapped") }
    )
    .padding()
    .background(Color.gymBackground)
}

#Preview("Without Action") {
    EmptyStateView(
        icon: "trophy",
        title: "No PRs Yet",
        message: "Keep training to set your first personal record!",
        iconColor: .gymWarning
    )
    .padding()
    .background(Color.gymBackground)
}

#Preview("Static Variants") {
    ScrollView {
        VStack(spacing: AppSpacing.section) {
            EmptyStateView.noWorkouts(action: {})
            EmptyStateView.noHistory()
            EmptyStateView.noPRs()
            EmptyStateView.noProgress()
        }
        .padding()
    }
    .background(Color.gymBackground)
}
