//
//  ExerciseListSheet.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

struct ExerciseListSheet: View {
    // MARK: - Properties

    let exerciseLogs: [ExerciseLog]
    let currentIndex: Int
    let onSelectExercise: (Int) -> Void
    let onReorderExercises: ((IndexSet, Int) -> Void)?
    let onDismiss: () -> Void

    // MARK: - State

    @State private var isEditing = false

    init(
        exerciseLogs: [ExerciseLog],
        currentIndex: Int,
        onSelectExercise: @escaping (Int) -> Void,
        onReorderExercises: ((IndexSet, Int) -> Void)? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.exerciseLogs = exerciseLogs
        self.currentIndex = currentIndex
        self.onSelectExercise = onSelectExercise
        self.onReorderExercises = onReorderExercises
        self.onDismiss = onDismiss
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground
                    .ignoresSafeArea()

                List {
                    ForEach(Array(exerciseLogs.enumerated()), id: \.element.id) { index, log in
                        ExerciseListRow(
                            exerciseLog: log,
                            index: index,
                            isCurrent: index == currentIndex,
                            isCompleted: !log.sets.isEmpty,
                            showGrip: onReorderExercises != nil
                        ) {
                            if !isEditing {
                                onSelectExercise(index)
                            }
                        }
                        .listRowBackground(Color.gymBackground)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .listRowSeparator(.hidden)
                    }
                    .onMove { source, destination in
                        onReorderExercises?(source, destination)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            }
            .navigationTitle("Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if onReorderExercises != nil {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isEditing.toggle()
                            }
                        } label: {
                            Text(isEditing ? "Done" : "Reorder")
                                .fontWeight(isEditing ? .semibold : .regular)
                        }
                        .foregroundStyle(Color.gymPrimary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundStyle(Color.gymPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Exercise List Row

struct ExerciseListRow: View {
    let exerciseLog: ExerciseLog
    let index: Int
    let isCurrent: Bool
    let isCompleted: Bool
    let showGrip: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // Grip handle on far left
                if showGrip {
                    gripHandle
                        .padding(.trailing, AppSpacing.small)
                }

                // Status indicator
                statusIndicator
                    .padding(.trailing, AppSpacing.component)

                // Exercise info
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(exerciseLog.exerciseName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.gymText)
                        .lineLimit(1)

                    if let muscle = exerciseLog.exercise?.primaryMuscle {
                        Text(muscle.displayName)
                            .font(.caption)
                            .foregroundStyle(Color.gymTextMuted)
                    }
                }

                Spacer()

                // Sets completed
                if isCompleted {
                    Text("\(exerciseLog.workingSets) sets")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.gymSuccess)
                        .padding(.trailing, AppSpacing.small)
                }

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)
            }
            .padding(.horizontal, AppSpacing.standard)
            .padding(.vertical, AppSpacing.component)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .fill(isCurrent ? Color.gymPrimary.opacity(0.12) : Color.gymCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .stroke(
                        isCurrent ? Color.gymPrimary.opacity(0.6) : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Grip Handle

    private var gripHandle: some View {
        VStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(Color.gymTextMuted.opacity(0.5))
                    .frame(width: 16, height: 2)
            }
        }
        .frame(width: 20)
    }

    // MARK: - Status Indicator

    private var statusIndicator: some View {
        ZStack {
            Circle()
                .fill(statusColor.opacity(0.2))
                .frame(width: 36, height: 36)

            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gymSuccess)
            } else if isCurrent {
                Circle()
                    .fill(Color.gymPrimary)
                    .frame(width: 12, height: 12)
            } else {
                Text("\(index + 1)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.gymTextMuted)
            }
        }
    }

    private var statusColor: Color {
        if isCompleted {
            return Color.gymSuccess
        } else if isCurrent {
            return Color.gymPrimary
        }
        return Color.gymCardHover
    }
}

// MARK: - Preview

#Preview {
    let log1 = ExerciseLog(exerciseOrder: 0)
    let log2 = ExerciseLog(exerciseOrder: 1)
    let log3 = ExerciseLog(exerciseOrder: 2)

    let set = SetLog(setNumber: 1, weight: 80, reps: 10)
    set.exerciseLog = log1
    log1.sets = [set]

    return ExerciseListSheet(
        exerciseLogs: [log1, log2, log3],
        currentIndex: 1,
        onSelectExercise: { _ in },
        onReorderExercises: { _, _ in },
        onDismiss: {}
    )
}
