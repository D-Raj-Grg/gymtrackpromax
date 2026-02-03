//
//  CompletedSetRow.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

struct CompletedSetRow: View {
    // MARK: - Properties

    let set: SetLog
    let exerciseType: ExerciseType
    let isPR: Bool
    let weightUnit: WeightUnit
    let onEdit: () -> Void
    let onDelete: () -> Void

    // MARK: - State

    @State private var showingDeleteAlert = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: AppSpacing.component) {
            // Set number indicator
            setIndicator

            // Display based on exercise type
            setDataDisplay

            Spacer()

            // RPE badge (if present) - not shown for pure duration exercises
            if let rpe = set.rpe, exerciseType != .duration {
                rpeBadge(rpe)
            }

            // PR badge (only for weight-based exercises)
            if isPR && exerciseType.showsWeight && exerciseType.showsReps {
                prBadge
            }

            // More options menu
            Menu {
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.subheadline)
                    .foregroundStyle(Color.gymTextMuted)
                    .frame(width: 32, height: 32)
            }
            .accessibilityLabel("More options for set \(set.setNumber)")
        }
        .padding(.horizontal, AppSpacing.component)
        .padding(.vertical, AppSpacing.small)
        .background(set.isWarmup ? Color.gymWarning.opacity(0.1) : Color.gymCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.small))
        .alert("Delete Set?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Set Indicator

    private var setIndicator: some View {
        ZStack {
            Circle()
                .fill(indicatorColor)
                .frame(width: 32, height: 32)

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
                Text("\(set.setNumber)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.gymText)
            }
        }
        .accessibilityLabel(set.isWarmup ? "Warmup set" : set.isDropset ? "Drop set" : "Set \(set.setNumber)")
    }

    private var indicatorColor: Color {
        if set.isWarmup {
            return Color.gymWarning.opacity(0.2)
        } else if set.isDropset {
            return Color.gymAccent.opacity(0.2)
        } else {
            return Color.gymCardHover
        }
    }

    // MARK: - Set Data Display

    @ViewBuilder
    private var setDataDisplay: some View {
        switch exerciseType {
        case .weightAndReps:
            weightRepsDisplay

        case .repsOnly:
            // Show weight if present, otherwise just reps
            if set.weight > 0 {
                weightRepsDisplay
            } else {
                repsOnlyDisplay
            }

        case .duration:
            durationOnlyDisplay

        case .weightAndDuration:
            weightDurationDisplay
        }
    }

    // MARK: - Weight/Reps Display

    private var weightRepsDisplay: some View {
        HStack(spacing: AppSpacing.xs) {
            Text(formattedWeight)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(Color.gymText)

            Text(weightUnit.symbol)
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)

            Text("×")
                .font(.body)
                .foregroundStyle(Color.gymTextMuted)

            Text("\(set.reps)")
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(Color.gymText)

            Text("reps")
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)
        }
    }

    // MARK: - Reps Only Display

    private var repsOnlyDisplay: some View {
        HStack(spacing: AppSpacing.xs) {
            Text("\(set.reps)")
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(Color.gymText)

            Text("reps")
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)
        }
    }

    // MARK: - Duration Only Display

    private var durationOnlyDisplay: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "timer")
                .font(.caption)
                .foregroundStyle(Color.gymAccent)

            Text(formattedDuration)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(Color.gymText)
        }
    }

    // MARK: - Weight + Duration Display

    private var weightDurationDisplay: some View {
        HStack(spacing: AppSpacing.xs) {
            Text(formattedWeight)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(Color.gymText)

            Text(weightUnit.symbol)
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)

            Text("×")
                .font(.body)
                .foregroundStyle(Color.gymTextMuted)

            Image(systemName: "timer")
                .font(.caption)
                .foregroundStyle(Color.gymAccent)

            Text(formattedDuration)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(Color.gymText)
        }
    }

    // MARK: - Formatters

    private var formattedWeight: String {
        if set.weight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(set.weight))"
        }
        return String(format: "%.1f", set.weight)
    }

    private var formattedDuration: String {
        guard let durationValue = set.duration else { return "0:00" }
        let mins = durationValue / 60
        let secs = durationValue % 60
        return String(format: "%d:%02d", mins, secs)
    }

    // MARK: - RPE Badge

    private func rpeBadge(_ rpe: Int) -> some View {
        Text("@\(rpe)")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(rpeColor(rpe))
            .padding(.horizontal, AppSpacing.small)
            .padding(.vertical, AppSpacing.xs)
            .background(rpeColor(rpe).opacity(0.15))
            .clipShape(Capsule())
    }

    private func rpeColor(_ rpe: Int) -> Color {
        switch rpe {
        case 1...6:
            return Color.gymSuccess
        case 7...8:
            return Color.gymWarning
        case 9...10:
            return Color.gymError
        default:
            return Color.gymTextMuted
        }
    }

    // MARK: - PR Badge

    private var prBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .font(.caption2)
            Text("PR")
                .font(.caption)
                .fontWeight(.bold)
        }
        .foregroundStyle(Color.gymWarning)
        .padding(.horizontal, AppSpacing.small)
        .padding(.vertical, AppSpacing.xs)
        .background(Color.gymWarning.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview("Weight × Reps") {
    VStack(spacing: AppSpacing.component) {
        CompletedSetRow(
            set: SetLog(setNumber: 1, weight: 60, reps: 10, isWarmup: true),
            exerciseType: .weightAndReps,
            isPR: false,
            weightUnit: .kg,
            onEdit: {},
            onDelete: {}
        )

        CompletedSetRow(
            set: SetLog(setNumber: 2, weight: 80, reps: 10, rpe: 7),
            exerciseType: .weightAndReps,
            isPR: false,
            weightUnit: .kg,
            onEdit: {},
            onDelete: {}
        )

        CompletedSetRow(
            set: SetLog(setNumber: 3, weight: 85, reps: 8, rpe: 9),
            exerciseType: .weightAndReps,
            isPR: true,
            weightUnit: .kg,
            onEdit: {},
            onDelete: {}
        )

        CompletedSetRow(
            set: SetLog(setNumber: 4, weight: 70, reps: 12, isDropset: true),
            exerciseType: .weightAndReps,
            isPR: false,
            weightUnit: .kg,
            onEdit: {},
            onDelete: {}
        )
    }
    .padding()
    .background(Color.gymBackground)
}

#Preview("Duration (Plank)") {
    VStack(spacing: AppSpacing.component) {
        CompletedSetRow(
            set: SetLog(setNumber: 1, duration: 30),
            exerciseType: .duration,
            isPR: false,
            weightUnit: .kg,
            onEdit: {},
            onDelete: {}
        )

        CompletedSetRow(
            set: SetLog(setNumber: 2, duration: 45),
            exerciseType: .duration,
            isPR: false,
            weightUnit: .kg,
            onEdit: {},
            onDelete: {}
        )

        CompletedSetRow(
            set: SetLog(setNumber: 3, duration: 60, isWarmup: true),
            exerciseType: .duration,
            isPR: false,
            weightUnit: .kg,
            onEdit: {},
            onDelete: {}
        )
    }
    .padding()
    .background(Color.gymBackground)
}

#Preview("Reps Only (Push-up)") {
    VStack(spacing: AppSpacing.component) {
        CompletedSetRow(
            set: SetLog(setNumber: 1, reps: 15),
            exerciseType: .repsOnly,
            isPR: false,
            weightUnit: .kg,
            onEdit: {},
            onDelete: {}
        )

        CompletedSetRow(
            set: SetLog(setNumber: 2, weight: 10, reps: 12),
            exerciseType: .repsOnly,
            isPR: false,
            weightUnit: .kg,
            onEdit: {},
            onDelete: {}
        )
    }
    .padding()
    .background(Color.gymBackground)
}

#Preview("Weight × Duration (Farmer's Walk)") {
    VStack(spacing: AppSpacing.component) {
        CompletedSetRow(
            set: SetLog(setNumber: 1, weight: 30, duration: 45),
            exerciseType: .weightAndDuration,
            isPR: false,
            weightUnit: .kg,
            onEdit: {},
            onDelete: {}
        )

        CompletedSetRow(
            set: SetLog(setNumber: 2, weight: 35, duration: 60),
            exerciseType: .weightAndDuration,
            isPR: false,
            weightUnit: .kg,
            onEdit: {},
            onDelete: {}
        )
    }
    .padding()
    .background(Color.gymBackground)
}
