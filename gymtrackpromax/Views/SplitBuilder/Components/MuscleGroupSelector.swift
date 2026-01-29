//
//  MuscleGroupSelector.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

/// Chip-based selector for muscle groups
struct MuscleGroupSelector: View {
    // MARK: - Properties

    @Binding var selectedMuscle: MuscleGroup?
    var allowDeselect: Bool = true
    var showAllOption: Bool = true

    // MARK: - Body

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.small) {
                if showAllOption {
                    allChip
                }

                ForEach(MuscleGroup.allCases, id: \.rawValue) { muscle in
                    muscleChip(muscle)
                }
            }
            .padding(.horizontal, AppSpacing.standard)
        }
    }

    // MARK: - All Chip

    private var allChip: some View {
        let isSelected = selectedMuscle == nil

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            selectedMuscle = nil
        } label: {
            Text("All")
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? Color.gymText : Color.gymTextMuted)
                .padding(.horizontal, AppSpacing.component)
                .padding(.vertical, AppSpacing.small)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.gymPrimary : Color.gymCard)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Show all muscles")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Muscle Chip

    private func muscleChip(_ muscle: MuscleGroup) -> some View {
        let isSelected = selectedMuscle == muscle

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if isSelected && allowDeselect {
                selectedMuscle = nil
            } else {
                selectedMuscle = muscle
            }
        } label: {
            Text(muscle.displayName)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? Color.gymText : Color.gymTextMuted)
                .padding(.horizontal, AppSpacing.component)
                .padding(.vertical, AppSpacing.small)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.gymPrimary : Color.gymCard)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(muscle.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Multi-select chip selector for muscle groups
struct MuscleGroupMultiSelector: View {
    // MARK: - Properties

    @Binding var selectedMuscles: Set<MuscleGroup>

    // MARK: - Body

    var body: some View {
        FlowLayout(spacing: AppSpacing.small) {
            ForEach(MuscleGroup.allCases, id: \.rawValue) { muscle in
                muscleChip(muscle)
            }
        }
    }

    // MARK: - Muscle Chip

    private func muscleChip(_ muscle: MuscleGroup) -> some View {
        let isSelected = selectedMuscles.contains(muscle)

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if isSelected {
                selectedMuscles.remove(muscle)
            } else {
                selectedMuscles.insert(muscle)
            }
        } label: {
            HStack(spacing: AppSpacing.xs) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption)
                }
                Text(muscle.displayName)
                    .font(.subheadline)
            }
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundStyle(isSelected ? Color.gymText : Color.gymTextMuted)
            .padding(.horizontal, AppSpacing.component)
            .padding(.vertical, AppSpacing.small)
            .background(
                Capsule()
                    .fill(isSelected ? Color.gymPrimary : Color.gymCard)
            )
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.clear : Color.gymBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(muscle.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Flow layout for wrapping content
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)

        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX - spacing)
        }

        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}

// MARK: - Preview

#Preview("Single Select") {
    struct PreviewWrapper: View {
        @State private var selected: MuscleGroup? = .chest

        var body: some View {
            VStack {
                MuscleGroupSelector(selectedMuscle: $selected)

                Text("Selected: \(selected?.displayName ?? "None")")
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gymBackground)
        }
    }

    return PreviewWrapper()
}

#Preview("Multi Select") {
    struct PreviewWrapper: View {
        @State private var selected: Set<MuscleGroup> = [.chest, .triceps]

        var body: some View {
            VStack(alignment: .leading, spacing: 20) {
                MuscleGroupMultiSelector(selectedMuscles: $selected)
                    .padding(.horizontal)

                Text("Selected: \(selected.map { $0.displayName }.joined(separator: ", "))")
                    .foregroundStyle(.white)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gymBackground)
        }
    }

    return PreviewWrapper()
}
