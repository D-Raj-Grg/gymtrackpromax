//
//  PRCard.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

struct PRCard: View {
    // MARK: - Properties

    let record: PRRecord
    let weightUnit: WeightUnit

    // MARK: - Computed Properties

    private var isRecent: Bool {
        let daysSincePR = Calendar.current.dateComponents([.day], from: record.date, to: Date()).day ?? 0
        return daysSincePR <= 7
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: AppSpacing.component) {
            // Trophy/Medal icon
            trophyIcon

            // Exercise info
            exerciseInfo

            Spacer()

            // PR details
            prDetails
        }
        .padding(AppSpacing.card)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.card)
                .fill(Color.gymCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.card)
                .stroke(
                    isRecent ? Color.gymSuccess.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
    }

    // MARK: - Trophy Icon

    private var trophyIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.gymSuccess.opacity(0.3), Color.gymSuccess.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)

            Image(systemName: isRecent ? "trophy.fill" : "trophy")
                .font(.title3)
                .foregroundStyle(
                    isRecent
                        ? Color.gymSuccess
                        : Color.gymSuccess.opacity(0.7)
                )
        }
    }

    // MARK: - Exercise Info

    private var exerciseInfo: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.small) {
                Text(record.exercise.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.gymText)
                    .lineLimit(1)

                if isRecent {
                    Text("NEW")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.gymSuccess)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.gymSuccess.opacity(0.2))
                        )
                }
            }

            HStack(spacing: AppSpacing.xs) {
                Image(systemName: record.exercise.primaryMuscle.iconName)
                    .font(.caption2)
                    .foregroundStyle(Color.gymPrimary)

                Text(record.exercise.primaryMuscle.displayName)
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)
            }

            Text(formattedDate)
                .font(.caption2)
                .foregroundStyle(Color.gymTextMuted.opacity(0.7))
        }
    }

    // MARK: - PR Details

    private var prDetails: some View {
        VStack(alignment: .trailing, spacing: AppSpacing.xs) {
            // Weight x Reps
            HStack(spacing: 2) {
                Text(formatWeight(record.weight))
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gymText)

                Text("x")
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)

                Text("\(record.reps)")
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gymText)
            }

            // Unit
            Text(weightUnit.symbol)
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)

            // Estimated 1RM
            HStack(spacing: 4) {
                Text("1RM:")
                    .font(.caption2)
                    .foregroundStyle(Color.gymTextMuted)

                Text("\(formatWeight(record.estimated1RM))")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.gymAccent)
            }
        }
    }

    // MARK: - Formatting

    private var formattedDate: String {
        let daysSince = Calendar.current.dateComponents([.day], from: record.date, to: Date()).day ?? 0

        if daysSince == 0 {
            return "Today"
        } else if daysSince == 1 {
            return "Yesterday"
        } else if daysSince < 7 {
            return "\(daysSince) days ago"
        } else {
            return record.date.formatted(.dateTime.month(.abbreviated).day().year())
        }
    }

    private func formatWeight(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(weight))"
        }
        return String(format: "%.1f", weight)
    }
}

// MARK: - Compact PR Card Variant

struct PRCardCompact: View {
    let record: PRRecord
    let weightUnit: WeightUnit

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Image(systemName: "trophy.fill")
                .font(.caption)
                .foregroundStyle(Color.gymSuccess)

            Text(record.exercise.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.gymText)
                .lineLimit(1)

            Spacer()

            Text("\(formatWeight(record.weight)) x \(record.reps)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.gymText)

            Text(weightUnit.symbol)
                .font(.caption2)
                .foregroundStyle(Color.gymTextMuted)
        }
        .padding(AppSpacing.component)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.small)
                .fill(Color.gymCard)
        )
    }

    private func formatWeight(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(weight))"
        }
        return String(format: "%.1f", weight)
    }
}

// MARK: - Preview

#Preview("Full PR Card") {
    let exercise = Exercise(
        name: "Bench Press",
        primaryMuscle: .chest,
        secondaryMuscles: [.triceps, .shoulders],
        equipment: .barbell
    )

    let record = PRRecord(
        exercise: exercise,
        weight: 100,
        reps: 5,
        estimated1RM: 116.67,
        date: Date(),
        sessionId: nil
    )

    return PRCard(record: record, weightUnit: .kg)
        .padding()
        .background(Color.gymBackground)
}

#Preview("Older PR Card") {
    let exercise = Exercise(
        name: "Deadlift",
        primaryMuscle: .back,
        secondaryMuscles: [.hamstrings, .glutes],
        equipment: .barbell
    )

    let record = PRRecord(
        exercise: exercise,
        weight: 180,
        reps: 3,
        estimated1RM: 198,
        date: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
        sessionId: nil
    )

    return PRCard(record: record, weightUnit: .kg)
        .padding()
        .background(Color.gymBackground)
}

#Preview("Compact PR Card") {
    let exercise = Exercise(
        name: "Squat",
        primaryMuscle: .quads,
        equipment: .barbell
    )

    let record = PRRecord(
        exercise: exercise,
        weight: 140,
        reps: 5,
        estimated1RM: 163.33,
        date: Date(),
        sessionId: nil
    )

    return PRCardCompact(record: record, weightUnit: .kg)
        .padding()
        .background(Color.gymBackground)
}
