//
//  SplitListRow.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

/// Row component displaying a workout split in the list
struct SplitListRow: View {
    // MARK: - Properties

    let split: WorkoutSplit
    var isActive: Bool
    var onTap: (() -> Void)?
    var onSetActive: (() -> Void)?
    var onDelete: (() -> Void)?

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            // Radio button - Tappable to activate
            Button {
                if !isActive {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onSetActive?()
                }
            } label: {
                Group {
                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.gymSuccess)
                    } else {
                        Circle()
                            .strokeBorder(Color.gymBorder, lineWidth: 2)
                            .frame(width: 22, height: 22)
                    }
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Main content - Tappable to edit
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onTap?()
            } label: {
                HStack(spacing: AppSpacing.component) {
                    // Split Info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: AppSpacing.small) {
                            Text(split.name)
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.gymText)

                            if split.splitType != .custom {
                                Text(split.splitType.shortName)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.gymPrimary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(Color.gymPrimary.opacity(0.15))
                                    )
                            }

                            if isActive {
                                Text("Active")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.gymSuccess)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(Color.gymSuccess.opacity(0.15))
                                    )
                            }
                        }

                        HStack(spacing: AppSpacing.small) {
                            // Days count
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                                Text("\(split.daysCount) days")
                                    .font(.caption)
                            }

                            Text("•")

                            // Total exercises
                            let totalExercises = split.workoutDays.reduce(0) { $0 + $1.exerciseCount }
                            HStack(spacing: 4) {
                                Image(systemName: "dumbbell.fill")
                                    .font(.caption2)
                                Text("\(totalExercises) exercises")
                                    .font(.caption)
                            }
                        }
                        .foregroundStyle(Color.gymTextMuted)

                        // Day names preview
                        if !split.workoutDays.isEmpty {
                            Text(split.sortedWorkoutDays.prefix(4).map { $0.name }.joined(separator: " • ") + (split.sortedWorkoutDays.count > 4 ? " •..." : ""))
                                .font(.caption)
                                .foregroundStyle(Color.gymTextMuted)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // Edit indicator
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.gymTextMuted)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, AppSpacing.small)
        .padding(.trailing, AppSpacing.component)
        .padding(.vertical, AppSpacing.component)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.card)
                .fill(isActive ? Color.gymSuccess.opacity(0.05) : Color.gymCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.card)
                .strokeBorder(isActive ? Color.gymSuccess.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .contextMenu {
            if !isActive {
                Button {
                    onSetActive?()
                } label: {
                    Label("Set as Active", systemImage: "checkmark.circle")
                }
            }

            Button {
                onTap?()
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            if !isActive {
                Button(role: .destructive) {
                    onDelete?()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if !isActive {
                Button(role: .destructive) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onDelete?()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }

            if !isActive {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onSetActive?()
                } label: {
                    Label("Activate", systemImage: "checkmark.circle")
                }
                .tint(Color.gymSuccess)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(split.name), \(split.daysCount) days\(isActive ? ", active" : "")")
        .accessibilityHint(isActive ? "Double tap to edit" : "Tap radio button to activate, or double tap to edit")
    }
}

/// Compact row for selection lists
struct SplitListRowCompact: View {
    // MARK: - Properties

    let split: WorkoutSplit
    var isSelected: Bool
    var onTap: (() -> Void)?

    // MARK: - Body

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap?()
        } label: {
            HStack(spacing: AppSpacing.component) {
                // Selection Indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.gymPrimary : Color.gymTextMuted)

                // Split Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(split.name)
                        .font(.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(Color.gymText)

                    Text("\(split.daysCount) days • \(split.splitType.displayName)")
                        .font(.caption)
                        .foregroundStyle(Color.gymTextMuted)
                }

                Spacer()
            }
            .padding(AppSpacing.component)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .fill(isSelected ? Color.gymPrimary.opacity(0.1) : Color.gymCard)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Standard") {
    let split = WorkoutSplit(name: "Push Pull Legs", splitType: .ppl)

    return VStack(spacing: AppSpacing.component) {
        SplitListRow(
            split: split,
            isActive: true,
            onTap: { print("Tapped") },
            onSetActive: { print("Set Active") },
            onDelete: { print("Delete") }
        )

        SplitListRow(
            split: WorkoutSplit(name: "Upper/Lower Split", splitType: .upperLower),
            isActive: false,
            onTap: { print("Tapped") },
            onSetActive: { print("Set Active") },
            onDelete: { print("Delete") }
        )

        SplitListRow(
            split: WorkoutSplit(name: "My Custom Routine", splitType: .custom),
            isActive: false,
            onTap: { print("Tapped") },
            onSetActive: { print("Set Active") },
            onDelete: { print("Delete") }
        )
    }
    .padding()
    .background(Color.gymBackground)
}

#Preview("Compact") {
    VStack(spacing: AppSpacing.small) {
        SplitListRowCompact(
            split: WorkoutSplit(name: "Push Pull Legs", splitType: .ppl),
            isSelected: true,
            onTap: { print("Tapped") }
        )

        SplitListRowCompact(
            split: WorkoutSplit(name: "Upper/Lower", splitType: .upperLower),
            isSelected: false,
            onTap: { print("Tapped") }
        )
    }
    .padding()
    .background(Color.gymBackground)
}
