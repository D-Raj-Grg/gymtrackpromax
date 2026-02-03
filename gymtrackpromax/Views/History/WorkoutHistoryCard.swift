//
//  WorkoutHistoryCard.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI
import Foundation

/// Card displaying a workout session in history
struct WorkoutHistoryCard: View {
    // MARK: - Properties

    let session: WorkoutSession
    let weightUnit: WeightUnit
    var hasPR: Bool = false

    // MARK: - State

    @State private var isPressed = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: AppSpacing.component) {
            // Left content
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                // Workout name with PR badge
                HStack(spacing: AppSpacing.small) {
                    Text(session.workoutName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.gymText)

                    if hasPR {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(Color.gymWarning)
                            .accessibilityHidden(true)
                    }
                }

                // Date
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(Color.gymTextMuted)

                // Stats row
                HStack(spacing: AppSpacing.component) {
                    statLabel(icon: "dumbbell.fill", value: "\(session.exercisesCompleted) exercises")

                    if session.duration != nil {
                        statLabel(icon: "clock.fill", value: session.durationDisplay)
                    }

                    statLabel(icon: "scalemass.fill", value: "\(session.totalVolumeDisplay) \(weightUnit.symbol)")
                }
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.gymTextMuted)
        }
        .padding(AppSpacing.standard)
        .background(isPressed ? Color.gymCardHover : Color.gymCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
        .contentShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }

    // MARK: - Subviews

    private func statLabel(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .accessibilityHidden(true)
            Text(value)
        }
    }

    // MARK: - Computed Properties

    private var formattedDate: String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(session.startTime) {
            return "Today at \(timeString)"
        } else if calendar.isDateInYesterday(session.startTime) {
            return "Yesterday at \(timeString)"
        } else if let daysAgo = calendar.dateComponents([.day], from: session.startTime, to: now).day,
                  daysAgo < 7 {
            let formatter = Foundation.DateFormatter()
            formatter.dateFormat = "EEEE"
            return "\(formatter.string(from: session.startTime)) at \(timeString)"
        } else {
            let formatter = Foundation.DateFormatter()
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: session.startTime)) at \(timeString)"
        }
    }

    private var timeString: String {
        let formatter = Foundation.DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: session.startTime)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gymBackground.ignoresSafeArea()

        VStack(spacing: AppSpacing.component) {
            WorkoutHistoryCard(
                session: {
                    let session = WorkoutSession(
                        startTime: Date(),
                        endTime: Date().addingTimeInterval(3600)
                    )
                    return session
                }(),
                weightUnit: .kg,
                hasPR: true
            )

            WorkoutHistoryCard(
                session: {
                    let session = WorkoutSession(
                        startTime: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                        endTime: Calendar.current.date(byAdding: .day, value: -1, to: Date())!.addingTimeInterval(2700)
                    )
                    return session
                }(),
                weightUnit: .lbs
            )
        }
        .padding()
    }
}
