//
//  ExerciseDetailView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI
import SwiftData

/// Detailed view for a single exercise
struct ExerciseDetailView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    let exercise: Exercise
    var isSelectionMode: Bool = false
    var onAddToWorkout: ((Exercise) -> Void)?

    // MARK: - State

    @State private var showingEditSheet: Bool = false
    @State private var showingDeleteConfirmation: Bool = false
    @State private var deleteError: String?
    @State private var showingDeleteError: Bool = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.section) {
                        // Header
                        exerciseHeader

                        // Muscle Groups
                        muscleGroupsSection

                        // Equipment
                        equipmentSection

                        // Instructions (if available)
                        if let instructions = exercise.instructions, !instructions.isEmpty {
                            instructionsSection(instructions)
                        }

                        // Add to workout button (in selection mode)
                        if isSelectionMode {
                            addToWorkoutButton
                        }

                        // Edit/Delete buttons (for custom exercises only)
                        if exercise.isCustom && !isSelectionMode {
                            managementButtons
                        }

                        Spacer(minLength: AppSpacing.xl)
                    }
                    .padding(.top, AppSpacing.standard)
                }
            }
            .navigationTitle("Exercise Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    }
                    .foregroundStyle(Color.gymTextMuted)
                }

                if exercise.isCustom {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                showingEditSheet = true
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundStyle(Color.gymText)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                EditExerciseView(exercise: exercise) {
                    // Refresh after edit
                }
            }
            .confirmationDialog(
                "Delete Exercise?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deleteExercise()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete '\(exercise.name)'. This cannot be undone.")
            }
            .alert("Cannot Delete", isPresented: $showingDeleteError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deleteError ?? "An error occurred")
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Exercise Header

    private var exerciseHeader: some View {
        VStack(spacing: AppSpacing.component) {
            // Equipment icon
            ZStack {
                Circle()
                    .fill(Color.gymPrimary.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: exercise.equipment.iconName)
                    .font(.system(size: 32))
                    .foregroundStyle(Color.gymPrimary)
            }

            // Name
            HStack(spacing: AppSpacing.small) {
                Text(exercise.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gymText)
                    .multilineTextAlignment(.center)

                if exercise.isCustom {
                    Text("Custom")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.gymAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.gymAccent.opacity(0.15))
                        )
                }
            }

            // Category badges
            HStack(spacing: AppSpacing.small) {
                categoryBadge(exercise.pplCategory.displayName, color: .gymPrimary)
                categoryBadge(exercise.bodyRegion.displayName, color: .gymAccent)
                if exercise.isCompound {
                    categoryBadge("Compound", color: .gymSuccess)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppSpacing.standard)
    }

    private func categoryBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(color)
            .padding(.horizontal, AppSpacing.component)
            .padding(.vertical, AppSpacing.xs)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
            )
    }

    // MARK: - Muscle Groups Section

    private var muscleGroupsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            Text("Muscles Targeted")
                .font(.headline)
                .foregroundStyle(Color.gymText)

            // Primary muscle
            muscleRow(exercise.primaryMuscle, isPrimary: true)

            // Secondary muscles
            if !exercise.secondaryMuscles.isEmpty {
                ForEach(exercise.secondaryMuscles, id: \.rawValue) { muscle in
                    muscleRow(muscle, isPrimary: false)
                }
            }
        }
        .padding(.horizontal, AppSpacing.standard)
    }

    private func muscleRow(_ muscle: MuscleGroup, isPrimary: Bool) -> some View {
        HStack(spacing: AppSpacing.component) {
            Image(systemName: muscle.iconName)
                .font(.body)
                .foregroundStyle(isPrimary ? Color.gymPrimary : Color.gymTextMuted)
                .frame(width: 24)

            Text(muscle.displayName)
                .font(.body)
                .foregroundStyle(Color.gymText)

            Spacer()

            Text(isPrimary ? "Primary" : "Secondary")
                .font(.caption)
                .foregroundStyle(isPrimary ? Color.gymPrimary : Color.gymTextMuted)
                .padding(.horizontal, AppSpacing.component)
                .padding(.vertical, AppSpacing.xs)
                .background(
                    Capsule()
                        .fill(isPrimary ? Color.gymPrimary.opacity(0.15) : Color.gymCard)
                )
        }
        .padding(AppSpacing.component)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.card)
                .fill(Color.gymCard)
        )
    }

    // MARK: - Equipment Section

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            Text("Equipment Required")
                .font(.headline)
                .foregroundStyle(Color.gymText)

            HStack(spacing: AppSpacing.component) {
                Image(systemName: exercise.equipment.iconName)
                    .font(.title2)
                    .foregroundStyle(Color.gymPrimary)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.equipment.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.gymText)

                    Text("Standard increment: \(String(format: "%.1f", exercise.weightIncrement)) kg")
                        .font(.caption)
                        .foregroundStyle(Color.gymTextMuted)
                }

                Spacer()
            }
            .padding(AppSpacing.component)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .fill(Color.gymCard)
            )
        }
        .padding(.horizontal, AppSpacing.standard)
    }

    // MARK: - Instructions Section

    private func instructionsSection(_ instructions: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            Text("Instructions")
                .font(.headline)
                .foregroundStyle(Color.gymText)

            Text(instructions)
                .font(.body)
                .foregroundStyle(Color.gymText)
                .padding(AppSpacing.component)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: AppCornerRadius.card)
                        .fill(Color.gymCard)
                )
        }
        .padding(.horizontal, AppSpacing.standard)
    }

    // MARK: - Add to Workout Button

    private var addToWorkoutButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onAddToWorkout?(exercise)
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add to Workout")
            }
            .font(.body)
            .fontWeight(.semibold)
            .foregroundStyle(Color.gymText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.component)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.button)
                    .fill(Color.gymPrimary)
            )
        }
        .padding(.horizontal, AppSpacing.standard)
    }

    // MARK: - Management Buttons

    private var managementButtons: some View {
        VStack(spacing: AppSpacing.component) {
            // Edit button
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showingEditSheet = true
            } label: {
                HStack {
                    Image(systemName: "pencil")
                    Text("Edit Exercise")
                }
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(Color.gymPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.component)
                .background(
                    RoundedRectangle(cornerRadius: AppCornerRadius.button)
                        .strokeBorder(Color.gymPrimary, lineWidth: 1.5)
                )
            }

            // Delete button
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showingDeleteConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Exercise")
                }
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(Color.gymError)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.component)
                .background(
                    RoundedRectangle(cornerRadius: AppCornerRadius.button)
                        .strokeBorder(Color.gymError.opacity(0.5), lineWidth: 1.5)
                )
            }
        }
        .padding(.horizontal, AppSpacing.standard)
    }

    // MARK: - Delete Exercise

    private func deleteExercise() {
        do {
            try ExerciseService.shared.deleteExercise(exercise, context: modelContext)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            deleteError = error.localizedDescription
            showingDeleteError = true
        }
    }
}

// MARK: - Preview

#Preview {
    let exercise = Exercise(
        name: "Barbell Bench Press",
        primaryMuscle: .chest,
        secondaryMuscles: [.triceps, .shoulders],
        equipment: .barbell,
        instructions: "Lie flat on a bench with your feet on the floor. Grip the barbell slightly wider than shoulder width. Lower the bar to your chest, then press it back up to the starting position.",
        isCustom: true
    )

    return ExerciseDetailView(exercise: exercise)
        .modelContainer(for: [Exercise.self], inMemory: true)
}
