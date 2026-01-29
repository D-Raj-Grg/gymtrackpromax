//
//  SwipeToDeleteContainer.swift
//  GymTrack Pro
//
//  Created by Claude Code on 29/01/26.
//

import SwiftUI

/// A container that adds swipe-to-delete functionality to any content
struct SwipeToDeleteContainer<Content: View>: View {
    // MARK: - Properties

    var isDisabled: Bool = false
    let onDelete: () -> Void
    @ViewBuilder let content: () -> Content

    // MARK: - State

    @State private var offset: CGFloat = 0
    @State private var isSwiped: Bool = false

    // MARK: - Constants

    private let deleteButtonWidth: CGFloat = 72
    private let fullSwipeThreshold: CGFloat = -160
    private let partialSwipeThreshold: CGFloat = -50

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete button revealed behind content
            if !isDisabled {
                deleteBackground
            }

            // Main content
            content()
                .offset(x: isDisabled ? 0 : offset)
                .gesture(isDisabled ? nil : swipeGesture)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
        .onChange(of: isDisabled) { _, disabled in
            if disabled {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    offset = 0
                    isSwiped = false
                }
            }
        }
    }

    // MARK: - Delete Background

    private var deleteBackground: some View {
        HStack(spacing: 0) {
            Spacer()

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    offset = 0
                    isSwiped = false
                }
                onDelete()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "trash.fill")
                        .font(.body)
                    Text("Delete")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .frame(width: deleteButtonWidth)
                .frame(maxHeight: .infinity)
            }
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: AppCornerRadius.card,
                    topTrailingRadius: AppCornerRadius.card
                )
                .fill(Color.red)
            )
        }
    }

    // MARK: - Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .local)
            .onChanged { value in
                // Only allow left swipe
                let translation = value.translation.width
                if isSwiped {
                    // Already swiped open - allow moving further left or back right
                    let newOffset = translation - deleteButtonWidth
                    offset = min(0, newOffset)
                } else if translation < 0 {
                    // Initial left swipe with resistance
                    offset = translation
                }
            }
            .onEnded { value in
                let velocity = value.predictedEndTranslation.width
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if value.translation.width < fullSwipeThreshold || velocity < -500 {
                        // Full swipe → reveal delete button (same as partial)
                        offset = -deleteButtonWidth
                        isSwiped = true
                    } else if value.translation.width < partialSwipeThreshold || (isSwiped && value.translation.width < 0) {
                        // Partial swipe → reveal delete button
                        offset = -deleteButtonWidth
                        isSwiped = true
                    } else {
                        // Snap back
                        offset = 0
                        isSwiped = false
                    }
                }
            }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: AppSpacing.component) {
        SwipeToDeleteContainer(onDelete: { print("Deleted 1") }) {
            HStack {
                Text("Swipe me left to delete")
                    .foregroundStyle(Color.gymText)
                Spacer()
            }
            .padding(AppSpacing.component)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .fill(Color.gymCard)
            )
        }

        SwipeToDeleteContainer(onDelete: { print("Deleted 2") }) {
            HStack {
                Text("Another item")
                    .foregroundStyle(Color.gymText)
                Spacer()
            }
            .padding(AppSpacing.component)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .fill(Color.gymCard)
            )
        }
    }
    .padding()
    .background(Color.gymBackground)
}
