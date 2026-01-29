//
//  ExerciseLibraryView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI
import SwiftData

/// View for browsing the full exercise library
struct ExerciseLibraryView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Exercise.name)
    private var allExercises: [Exercise]

    // MARK: - Properties

    /// Optional callback when exercise is selected (for adding to workout day)
    var onExerciseSelected: ((Exercise) -> Void)?

    /// Whether we're in selection mode (from WorkoutDayEditorView)
    var isSelectionMode: Bool = false

    // MARK: - State

    @State private var searchQuery: String = ""
    @State private var selectedMuscleFilter: MuscleGroup?
    @State private var filterMode: FilterMode = .all
    @State private var selectedExercise: Exercise?
    @State private var showingAddExercise: Bool = false

    // MARK: - Filter Mode

    enum FilterMode: String, CaseIterable {
        case all = "All"
        case custom = "Custom"
        case byMuscle = "By Muscle"
    }

    // MARK: - Computed Properties

    private var filteredExercises: [Exercise] {
        var filtered = allExercises

        // Filter by custom only
        if filterMode == .custom {
            filtered = filtered.filter { $0.isCustom }
        }

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

    private var customExerciseCount: Int {
        allExercises.filter { $0.isCustom }.count
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

                    // Filter Segment
                    filterSegment

                    // Muscle Filter (when By Muscle is selected)
                    if filterMode == .byMuscle {
                        MuscleGroupSelector(
                            selectedMuscle: $selectedMuscleFilter,
                            allowDeselect: true,
                            showAllOption: true
                        )
                        .padding(.vertical, AppSpacing.small)
                    }

                    // Stats bar
                    statsBar

                    // Exercise List
                    if filteredExercises.isEmpty {
                        emptyState
                    } else {
                        exerciseList
                    }
                }
            }
            .navigationTitle("Exercise Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(isSelectionMode ? "Cancel" : "Done") {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    }
                    .foregroundStyle(Color.gymTextMuted)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showingAddExercise = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.gymPrimary)
                    }
                    .accessibilityLabel("Add custom exercise")
                }
            }
            .sheet(isPresented: $showingAddExercise) {
                AddExerciseView { newExercise in
                    // Optionally select new exercise
                    if isSelectionMode {
                        onExerciseSelected?(newExercise)
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedExercise) { exercise in
                ExerciseDetailView(
                    exercise: exercise,
                    isSelectionMode: isSelectionMode,
                    onAddToWorkout: isSelectionMode ? { selected in
                        onExerciseSelected?(selected)
                        dismiss()
                    } : nil
                )
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

    // MARK: - Filter Segment

    private var filterSegment: some View {
        HStack(spacing: AppSpacing.small) {
            ForEach(FilterMode.allCases, id: \.rawValue) { mode in
                filterChip(mode)
            }

            Spacer()
        }
        .padding(.horizontal, AppSpacing.standard)
        .padding(.vertical, AppSpacing.component)
    }

    private func filterChip(_ mode: FilterMode) -> some View {
        let isSelected = filterMode == mode

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(AppAnimation.spring) {
                filterMode = mode
                if mode != .byMuscle {
                    selectedMuscleFilter = nil
                }
            }
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Text(mode.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                if mode == .custom && customExerciseCount > 0 {
                    Text("\(customExerciseCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(isSelected ? Color.gymText : Color.gymAccent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.gymText.opacity(0.2) : Color.gymAccent.opacity(0.2))
                        )
                }
            }
            .foregroundStyle(isSelected ? Color.gymText : Color.gymTextMuted)
            .padding(.horizontal, AppSpacing.component)
            .padding(.vertical, AppSpacing.small)
            .background(
                Capsule()
                    .fill(isSelected ? Color.gymPrimary : Color.gymCard)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack {
            Text("\(filteredExercises.count) exercises")
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)

            Spacer()
        }
        .padding(.horizontal, AppSpacing.standard)
        .padding(.bottom, AppSpacing.small)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppSpacing.section) {
            Spacer()

            Image(systemName: filterMode == .custom ? "star.circle" : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(Color.gymTextMuted)

            Text(filterMode == .custom ? "No Custom Exercises" : "No Exercises Found")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color.gymText)

            Text(filterMode == .custom
                 ? "Create your own exercises to track unique movements"
                 : "Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundStyle(Color.gymTextMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.large)

            if filterMode == .custom {
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
            }

            Spacer()
        }
    }

    // MARK: - Exercise List

    private var exerciseList: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                ForEach(groupedExercises, id: \.0) { muscle, exercises in
                    Section {
                        ForEach(exercises) { exercise in
                            exerciseRow(exercise)
                        }
                    } header: {
                        sectionHeader(muscle, count: exercises.count)
                    }
                }
            }
            .padding(.bottom, AppSpacing.xl)
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ muscle: MuscleGroup, count: Int) -> some View {
        HStack {
            Image(systemName: muscle.iconName)
                .font(.caption)
                .foregroundStyle(Color.gymPrimary)

            Text(muscle.displayName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.gymText)

            Text("(\(count))")
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)

            Spacer()
        }
        .padding(.horizontal, AppSpacing.standard)
        .padding(.vertical, AppSpacing.small)
        .background(Color.gymBackground)
    }

    // MARK: - Exercise Row

    private func exerciseRow(_ exercise: Exercise) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            selectedExercise = exercise
        } label: {
            HStack(spacing: AppSpacing.component) {
                // Equipment icon
                ZStack {
                    Circle()
                        .fill(Color.gymCard)
                        .frame(width: 40, height: 40)

                    Image(systemName: exercise.equipment.iconName)
                        .font(.body)
                        .foregroundStyle(Color.gymPrimary)
                }

                // Exercise Info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: AppSpacing.small) {
                        Text(exercise.name)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.gymText)
                            .lineLimit(1)

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
                        Text(exercise.equipment.displayName)
                            .font(.caption)

                        if !exercise.secondaryMuscles.isEmpty {
                            Text("•")
                            Text(exercise.secondaryMuscles.prefix(2).map { $0.displayName }.joined(separator: ", "))
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                    .foregroundStyle(Color.gymTextMuted)
                }

                Spacer()

                // Chevron
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
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(exercise.name), \(exercise.equipment.displayName)")
    }
}

// MARK: - Preview

#Preview {
    ExerciseLibraryView()
        .modelContainer(for: [Exercise.self], inMemory: true)
}
