//
//  ExercisePickerView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI
import SwiftData

/// View for browsing, searching, and selecting exercises
struct ExercisePickerView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Exercise.name)
    private var allExercises: [Exercise]

    // MARK: - Properties

    var onExercisesSelected: (([Exercise]) -> Void)?
    var allowMultiSelect: Bool = true

    // MARK: - State

    @State private var searchQuery: String = ""
    @State private var selectedMuscleFilter: MuscleGroup?
    @State private var selectedExerciseIds: Set<UUID> = []
    @State private var showingAddExercise: Bool = false

    // MARK: - Computed Properties

    private var filteredExercises: [Exercise] {
        var filtered = allExercises

        // Filter by muscle group
        if let muscle = selectedMuscleFilter {
            filtered = filtered.filter { $0.primaryMuscle == muscle }
        }

        // Filter by search query
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            filtered = filtered.filter { $0.name.lowercased().contains(query) }
        }

        return filtered
    }

    private var groupedExercises: [(MuscleGroup, [Exercise])] {
        let grouped = Dictionary(grouping: filteredExercises) { $0.primaryMuscle }
        return MuscleGroup.allCases.compactMap { muscle in
            guard let exercises = grouped[muscle], !exercises.isEmpty else { return nil }
            return (muscle, exercises)
        }
    }

    private var selectedExercises: [Exercise] {
        allExercises.filter { selectedExerciseIds.contains($0.id) }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search Bar
                    searchBar

                    // Muscle Filter
                    MuscleGroupSelector(
                        selectedMuscle: $selectedMuscleFilter,
                        allowDeselect: true,
                        showAllOption: true
                    )
                    .padding(.vertical, AppSpacing.component)

                    // Exercise List
                    if filteredExercises.isEmpty {
                        emptyState
                    } else {
                        exerciseList
                    }
                }
            }
            .navigationTitle("Select Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    }
                    .foregroundStyle(Color.gymTextMuted)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if allowMultiSelect {
                        Button("Add (\(selectedExerciseIds.count))") {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            confirmSelection()
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(selectedExerciseIds.isEmpty ? Color.gymTextMuted : Color.gymPrimary)
                        .disabled(selectedExerciseIds.isEmpty)
                    }
                }
            }
            .sheet(isPresented: $showingAddExercise) {
                AddExerciseView { newExercise in
                    // Auto-select newly created exercise
                    selectedExerciseIds.insert(newExercise.id)
                }
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: AppSpacing.component) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.gymTextMuted)

            TextField("Search exercises...", text: $searchQuery)
                .textFieldStyle(.plain)
                .font(.body)
                .foregroundStyle(Color.gymText)

            if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.gymTextMuted)
                }
            }
        }
        .padding(AppSpacing.component)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.input)
                .fill(Color.gymCard)
        )
        .padding(.horizontal, AppSpacing.standard)
        .padding(.top, AppSpacing.component)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppSpacing.section) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(Color.gymTextMuted)

            Text("No exercises found")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color.gymText)

            Text("Try adjusting your search or create a custom exercise")
                .font(.subheadline)
                .foregroundStyle(Color.gymTextMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.large)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showingAddExercise = true
            } label: {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Custom Exercise")
                }
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(Color.gymPrimary)
            }

            Spacer()
        }
    }

    // MARK: - Exercise List

    private var exerciseList: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                // Create Custom Exercise Button
                createCustomButton

                // Exercise Groups
                ForEach(groupedExercises, id: \.0) { muscle, exercises in
                    Section {
                        ForEach(exercises) { exercise in
                            exerciseRow(exercise)
                        }
                    } header: {
                        sectionHeader(muscle)
                    }
                }
            }
            .padding(.bottom, AppSpacing.xl)
        }
    }

    // MARK: - Create Custom Button

    private var createCustomButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showingAddExercise = true
        } label: {
            HStack(spacing: AppSpacing.component) {
                ZStack {
                    Circle()
                        .fill(Color.gymPrimary.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "plus")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.gymPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Create Custom Exercise")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.gymPrimary)

                    Text("Add your own exercise to the database")
                        .font(.caption)
                        .foregroundStyle(Color.gymTextMuted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)
            }
            .padding(AppSpacing.component)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .fill(Color.gymCard)
            )
            .padding(.horizontal, AppSpacing.standard)
            .padding(.vertical, AppSpacing.small)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section Header

    private func sectionHeader(_ muscle: MuscleGroup) -> some View {
        HStack {
            Image(systemName: muscle.iconName)
                .font(.caption)
                .foregroundStyle(Color.gymPrimary)

            Text(muscle.displayName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.gymText)

            Spacer()
        }
        .padding(.horizontal, AppSpacing.standard)
        .padding(.vertical, AppSpacing.small)
        .background(Color.gymBackground)
    }

    // MARK: - Exercise Row

    private func exerciseRow(_ exercise: Exercise) -> some View {
        let isSelected = selectedExerciseIds.contains(exercise.id)

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()

            if allowMultiSelect {
                if isSelected {
                    selectedExerciseIds.remove(exercise.id)
                } else {
                    selectedExerciseIds.insert(exercise.id)
                }
            } else {
                // Single select - immediately confirm
                onExercisesSelected?([exercise])
                dismiss()
            }
        } label: {
            HStack(spacing: AppSpacing.component) {
                // Selection Indicator
                if allowMultiSelect {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? Color.gymPrimary : Color.gymTextMuted)
                }

                // Exercise Info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: AppSpacing.small) {
                        Text(exercise.name)
                            .font(.body)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .foregroundStyle(Color.gymText)

                        if exercise.isCustom {
                            Text("Custom")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.gymAccent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.gymAccent.opacity(0.15))
                                )
                        }
                    }

                    HStack(spacing: AppSpacing.small) {
                        Image(systemName: exercise.equipment.iconName)
                            .font(.caption2)
                        Text(exercise.equipment.displayName)
                            .font(.caption)

                        if !exercise.secondaryMuscles.isEmpty {
                            Text("•")
                            Text(exercise.secondaryMuscles.map { $0.displayName }.joined(separator: ", "))
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                    .foregroundStyle(Color.gymTextMuted)
                }

                Spacer()

                if !allowMultiSelect {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.gymTextMuted)
                }
            }
            .padding(AppSpacing.component)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .fill(isSelected ? Color.gymPrimary.opacity(0.1) : Color.gymCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .strokeBorder(isSelected ? Color.gymPrimary.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .padding(.horizontal, AppSpacing.standard)
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(exercise.name), \(exercise.equipment.displayName)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Confirm Selection

    private func confirmSelection() {
        let selected = selectedExercises.sorted { $0.name < $1.name }
        onExercisesSelected?(selected)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    ExercisePickerView { exercises in
        print("Selected: \(exercises.map { $0.name })")
    }
    .modelContainer(for: [Exercise.self], inMemory: true)
}
