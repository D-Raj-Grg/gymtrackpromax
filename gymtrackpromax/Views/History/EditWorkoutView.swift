//
//  EditWorkoutView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 30/01/26.
//

import SwiftUI
import SwiftData

/// Sheet for editing a past workout session
struct EditWorkoutView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - Properties

    let session: WorkoutSession
    let weightUnit: WeightUnit

    // MARK: - State

    @State private var notes: String = ""
    @State private var editingSets: [UUID: (weight: Double, reps: Int)] = [:]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.section) {
                        // Notes section
                        notesSection

                        // Exercises
                        ForEach(session.sortedExerciseLogs) { exerciseLog in
                            exerciseSection(exerciseLog)
                        }

                        Spacer(minLength: AppSpacing.xl)
                    }
                    .padding(.top, AppSpacing.standard)
                }
            }
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.gymTextMuted)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.gymPrimary)
                }
            }
        }
        .onAppear {
            notes = session.notes ?? ""
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Notes")
                .font(.headline)
                .foregroundStyle(Color.gymText)

            TextField("Add workout notes...", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .padding(AppSpacing.standard)
                .background(Color.gymCard)
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.input))
                .foregroundStyle(Color.gymText)
        }
        .padding(.horizontal, AppSpacing.standard)
    }

    // MARK: - Exercise Section

    private func exerciseSection(_ exerciseLog: ExerciseLog) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            // Exercise header
            HStack {
                Text(exerciseLog.exerciseName)
                    .font(.headline)
                    .foregroundStyle(Color.gymText)

                Spacer()

                // Add set button
                Button {
                    addSet(to: exerciseLog)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Set")
                    }
                    .font(.caption)
                    .foregroundStyle(Color.gymPrimary)
                }
            }

            // Sets
            if exerciseLog.sortedSets.isEmpty {
                Text("No sets recorded")
                    .font(.subheadline)
                    .foregroundStyle(Color.gymTextMuted)
                    .padding(.vertical, AppSpacing.small)
            } else {
                // Header row
                HStack {
                    Text("Set")
                        .frame(width: 36, alignment: .leading)
                    Text("Weight")
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text("Reps")
                        .frame(width: 60, alignment: .center)
                    Spacer()
                        .frame(width: 36)
                }
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)
                .padding(.horizontal, AppSpacing.small)

                ForEach(exerciseLog.sortedSets) { set in
                    editableSetRow(set, exerciseLog: exerciseLog)
                }
            }
        }
        .padding(AppSpacing.standard)
        .background(Color.gymCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
        .padding(.horizontal, AppSpacing.standard)
    }

    // MARK: - Editable Set Row

    private func editableSetRow(_ set: SetLog, exerciseLog: ExerciseLog) -> some View {
        let weight = editingSets[set.id]?.weight ?? set.weight
        let reps = editingSets[set.id]?.reps ?? set.reps

        return HStack(spacing: AppSpacing.small) {
            // Set number
            Text("\(set.setNumber)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(set.isWarmup ? Color.gymWarning : Color.gymText)
                .frame(width: 36, alignment: .leading)

            // Weight input
            TextField("0", value: Binding(
                get: { weight },
                set: { newValue in
                    editingSets[set.id] = (weight: newValue, reps: reps)
                }
            ), format: .number)
            .keyboardType(.decimalPad)
            .font(.system(.subheadline, design: .monospaced))
            .foregroundStyle(Color.gymText)
            .multilineTextAlignment(.center)
            .padding(.vertical, AppSpacing.xs)
            .background(Color.gymBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.small))
            .frame(maxWidth: .infinity)

            // Reps input
            TextField("0", value: Binding(
                get: { reps },
                set: { newValue in
                    editingSets[set.id] = (weight: weight, reps: newValue)
                }
            ), format: .number)
            .keyboardType(.numberPad)
            .font(.system(.subheadline, design: .monospaced))
            .foregroundStyle(Color.gymText)
            .multilineTextAlignment(.center)
            .padding(.vertical, AppSpacing.xs)
            .background(Color.gymBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.small))
            .frame(width: 60)

            // Delete button
            Button {
                deleteSet(set, from: exerciseLog)
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(Color.gymError)
            }
            .frame(width: 36)
        }
        .padding(.horizontal, AppSpacing.small)
    }

    // MARK: - Actions

    private func saveChanges() {
        // Save notes
        session.notes = notes.isEmpty ? nil : notes

        // Save edited sets
        for (setId, values) in editingSets {
            if let exerciseLog = session.exerciseLogs.first(where: { log in
                log.sets.contains { $0.id == setId }
            }),
               let set = exerciseLog.sets.first(where: { $0.id == setId }) {
                set.weight = values.weight
                set.reps = values.reps
            }
        }

        try? modelContext.save()
        HapticManager.setLogged()
        dismiss()
    }

    private func deleteSet(_ set: SetLog, from exerciseLog: ExerciseLog) {
        exerciseLog.sets.removeAll { $0.id == set.id }

        // Renumber remaining sets
        for (index, remainingSet) in exerciseLog.sortedSets.enumerated() {
            remainingSet.setNumber = index + 1
        }

        modelContext.delete(set)
        editingSets.removeValue(forKey: set.id)
        HapticManager.buttonTap()
    }

    private func addSet(to exerciseLog: ExerciseLog) {
        let setNumber = exerciseLog.sets.count + 1
        let lastSet = exerciseLog.sortedSets.last

        let newSet = SetLog(
            setNumber: setNumber,
            weight: lastSet?.weight ?? 0,
            reps: lastSet?.reps ?? 0
        )
        newSet.exerciseLog = exerciseLog
        exerciseLog.sets.append(newSet)
        modelContext.insert(newSet)
        HapticManager.buttonTap()
    }
}

// MARK: - Preview

#Preview {
    EditWorkoutView(
        session: WorkoutSession(
            startTime: Date().addingTimeInterval(-3600),
            endTime: Date(),
            notes: "Good workout"
        ),
        weightUnit: .kg
    )
    .modelContainer(for: [WorkoutSession.self, ExerciseLog.self, SetLog.self], inMemory: true)
}
