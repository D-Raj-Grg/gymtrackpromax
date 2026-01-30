//
//  ExerciseLogView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI
import SwiftData

struct ExerciseLogView: View {
    // MARK: - Properties

    let exerciseLog: ExerciseLog
    let plannedExercise: PlannedExercise?
    let previousPerformance: String?
    let achievedPRs: [PRInfo]
    let weightUnit: WeightUnit

    @Binding var pendingWeight: Double
    @Binding var pendingReps: Int
    @Binding var pendingDuration: Int
    @Binding var pendingRPE: Int?
    @Binding var isWarmup: Bool
    @Binding var isDropset: Bool

    let canDuplicateLastSet: Bool
    let onLogSet: () -> Void
    let onDuplicateLastSet: () -> Void
    let onDeleteSet: (SetLog) -> Void
    let onEditSet: (SetLog) -> Void
    let onIncrementWeight: () -> Void
    let onDecrementWeight: () -> Void
    let onIncrementReps: () -> Void
    let onDecrementReps: () -> Void
    let onNotesChanged: (String) -> Void

    // MARK: - State

    @State private var showNotesField: Bool = false
    @State private var notesText: String = ""

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.standard) {
                // Exercise header
                exerciseHeader

                // Previous performance reference
                if let previous = previousPerformance {
                    previousPerformanceView(previous)
                }

                // Exercise notes
                exerciseNotesSection

                // Completed sets
                if !exerciseLog.sortedSets.isEmpty {
                    completedSetsSection
                }

                // Set input
                SetInputView(
                    weight: $pendingWeight,
                    reps: $pendingReps,
                    duration: $pendingDuration,
                    rpe: $pendingRPE,
                    isWarmup: $isWarmup,
                    isDropset: $isDropset,
                    exerciseType: exerciseLog.exercise?.exerciseType ?? .weightAndReps,
                    weightUnit: weightUnit,
                    canDuplicateLastSet: canDuplicateLastSet,
                    onLogSet: onLogSet,
                    onDuplicateLastSet: onDuplicateLastSet,
                    onIncrementWeight: onIncrementWeight,
                    onDecrementWeight: onDecrementWeight,
                    onIncrementReps: onIncrementReps,
                    onDecrementReps: onDecrementReps
                )

                Spacer(minLength: AppSpacing.xl)
                }
                .frame(width: geometry.size.width - 32)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, AppSpacing.small)
            }
            .frame(width: geometry.size.width)
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: - Exercise Header

    private var exerciseHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            // Exercise name
            Text(exerciseLog.exerciseName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.gymText)

            // Exercise details
            HStack(spacing: AppSpacing.component) {
                // Muscle group
                if let muscle = exerciseLog.exercise?.primaryMuscle {
                    Label(muscle.displayName, systemImage: muscle.iconName)
                        .font(.caption)
                        .foregroundStyle(Color.gymTextMuted)
                }

                // Target sets/reps
                if let planned = plannedExercise {
                    Text(planned.setsAndRepsDisplay)
                        .font(.caption)
                        .foregroundStyle(Color.gymTextMuted)

                    Text(planned.restDisplay)
                        .font(.caption)
                        .foregroundStyle(Color.gymTextMuted)
                }
            }
        }
        .padding(.vertical, AppSpacing.small)
    }

    // MARK: - Previous Performance

    private func previousPerformanceView(_ performance: String) -> some View {
        HStack {
            HStack(spacing: AppSpacing.small) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)

                Text("Last: \(performance)")
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)
            }
            .padding(.horizontal, AppSpacing.component)
            .padding(.vertical, AppSpacing.small)
            .background(Color.gymCard.opacity(0.5))
            .clipShape(Capsule())

            Spacer()
        }
    }

    // MARK: - Completed Sets Section

    private var completedSetsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            // Section header
            HStack {
                Text("Completed Sets")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.gymText)

                Spacer()

                // Volume display (only for weight-based exercises)
                if currentExerciseType.showsWeight && currentExerciseType.showsReps {
                    Text("\(Int(exerciseLog.totalVolume)) \(weightUnit.symbol)")
                        .font(.caption)
                        .foregroundStyle(Color.gymTextMuted)
                }
            }

            // Sets list
            VStack(spacing: AppSpacing.small) {
                ForEach(exerciseLog.sortedSets) { set in
                    CompletedSetRow(
                        set: set,
                        exerciseType: currentExerciseType,
                        isPR: isPR(set),
                        weightUnit: weightUnit,
                        onEdit: { onEditSet(set) },
                        onDelete: { onDeleteSet(set) }
                    )
                }
            }
        }
    }

    /// The exercise type for the current exercise
    private var currentExerciseType: ExerciseType {
        exerciseLog.exercise?.exerciseType ?? .weightAndReps
    }

    // MARK: - Exercise Notes Section

    private var exerciseNotesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            if showNotesField || !notesText.isEmpty {
                // Notes input field
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack {
                        Image(systemName: "note.text")
                            .font(.caption)
                            .foregroundStyle(Color.gymTextMuted)

                        Text("Notes")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.gymTextMuted)

                        Spacer()

                        if !notesText.isEmpty {
                            Button {
                                HapticManager.buttonTap()
                                notesText = ""
                                onNotesChanged("")
                                showNotesField = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.gymTextMuted)
                            }
                        }
                    }

                    TextField("Add notes for this exercise...", text: $notesText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.subheadline)
                        .foregroundStyle(Color.gymText)
                        .lineLimit(2...4)
                        .onChange(of: notesText) { _, newValue in
                            onNotesChanged(newValue)
                        }
                }
                .padding(AppSpacing.component)
                .background(
                    RoundedRectangle(cornerRadius: AppCornerRadius.card)
                        .fill(Color.gymCard)
                )
            } else {
                // Add notes button
                Button {
                    HapticManager.buttonTap()
                    showNotesField = true
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "plus.circle")
                            .font(.caption)
                        Text("Add Note")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(Color.gymTextMuted)
                    .padding(.horizontal, AppSpacing.component)
                    .padding(.vertical, AppSpacing.small)
                    .background(
                        RoundedRectangle(cornerRadius: AppCornerRadius.button)
                            .fill(Color.gymCard)
                    )
                }
            }
        }
        .onAppear {
            // Initialize from exercise log
            notesText = exerciseLog.notes ?? ""
            showNotesField = !notesText.isEmpty
        }
        .onChange(of: exerciseLog.id) { _, _ in
            // Update when switching exercises
            notesText = exerciseLog.notes ?? ""
            showNotesField = !notesText.isEmpty
        }
    }

    // MARK: - Helpers

    private func isPR(_ set: SetLog) -> Bool {
        achievedPRs.contains { pr in
            pr.exerciseName == exerciseLog.exerciseName &&
            abs(pr.value - set.estimated1RM) < 0.01
        }
    }
}

// MARK: - Preview

#Preview("Weight × Reps") {
    @Previewable @State var weight: Double = 80.0
    @Previewable @State var reps: Int = 10
    @Previewable @State var duration: Int = 0
    @Previewable @State var rpe: Int? = nil
    @Previewable @State var isWarmup: Bool = false
    @Previewable @State var isDropset: Bool = false

    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ExerciseLog.self, SetLog.self, Exercise.self,
        configurations: config
    )

    let exerciseLog = ExerciseLog(exerciseOrder: 0)
    let exercise = Exercise(
        name: "Barbell Bench Press",
        primaryMuscle: .chest,
        secondaryMuscles: [.triceps, .shoulders],
        equipment: .barbell
    )
    exerciseLog.exercise = exercise

    // Add some sets
    let set1 = SetLog(setNumber: 1, weight: 60, reps: 10, isWarmup: true)
    let set2 = SetLog(setNumber: 2, weight: 80, reps: 10, rpe: 7)
    set1.exerciseLog = exerciseLog
    set2.exerciseLog = exerciseLog
    exerciseLog.sets = [set1, set2]

    return ExerciseLogView(
        exerciseLog: exerciseLog,
        plannedExercise: nil,
        previousPerformance: "80kg × 10, 82.5kg × 8",
        achievedPRs: [],
        weightUnit: .kg,
        pendingWeight: $weight,
        pendingReps: $reps,
        pendingDuration: $duration,
        pendingRPE: $rpe,
        isWarmup: $isWarmup,
        isDropset: $isDropset,
        canDuplicateLastSet: true,
        onLogSet: {},
        onDuplicateLastSet: {},
        onDeleteSet: { _ in },
        onEditSet: { _ in },
        onIncrementWeight: { weight += 0.5 },
        onDecrementWeight: { weight -= 0.5 },
        onIncrementReps: { reps += 1 },
        onDecrementReps: { reps -= 1 },
        onNotesChanged: { print("Notes: \($0)") }
    )
    .background(Color.gymBackground)
    .modelContainer(container)
}

#Preview("Duration (Plank)") {
    @Previewable @State var weight: Double = 0
    @Previewable @State var reps: Int = 0
    @Previewable @State var duration: Int = 45
    @Previewable @State var rpe: Int? = nil
    @Previewable @State var isWarmup: Bool = false
    @Previewable @State var isDropset: Bool = false

    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ExerciseLog.self, SetLog.self, Exercise.self,
        configurations: config
    )

    let exerciseLog = ExerciseLog(exerciseOrder: 0)
    let exercise = Exercise(
        name: "Plank",
        primaryMuscle: .abs,
        secondaryMuscles: [],
        equipment: .bodyweight,
        exerciseType: .duration
    )
    exerciseLog.exercise = exercise

    // Add some duration sets
    let set1 = SetLog(setNumber: 1, duration: 30)
    let set2 = SetLog(setNumber: 2, duration: 45)
    set1.exerciseLog = exerciseLog
    set2.exerciseLog = exerciseLog
    exerciseLog.sets = [set1, set2]

    return ExerciseLogView(
        exerciseLog: exerciseLog,
        plannedExercise: nil,
        previousPerformance: "0:30, 0:45",
        achievedPRs: [],
        weightUnit: .kg,
        pendingWeight: $weight,
        pendingReps: $reps,
        pendingDuration: $duration,
        pendingRPE: $rpe,
        isWarmup: $isWarmup,
        isDropset: $isDropset,
        canDuplicateLastSet: true,
        onLogSet: {},
        onDuplicateLastSet: {},
        onDeleteSet: { _ in },
        onEditSet: { _ in },
        onIncrementWeight: {},
        onDecrementWeight: {},
        onIncrementReps: {},
        onDecrementReps: {},
        onNotesChanged: { print("Notes: \($0)") }
    )
    .background(Color.gymBackground)
    .modelContainer(container)
}
