//
//  SplitBuilderViewModel.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import Foundation
import SwiftData
import SwiftUI
import WidgetKit

/// Errors that can occur during split/exercise operations
enum SplitBuilderError: LocalizedError {
    case duplicateName
    case emptyName
    case noWorkoutDays
    case cannotEditDefaultExercise
    case cannotDeleteDefaultExercise
    case cannotDeleteActiveSplit
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .duplicateName:
            return "An item with this name already exists"
        case .emptyName:
            return "Name cannot be empty"
        case .noWorkoutDays:
            return "Split must have at least one workout day"
        case .cannotEditDefaultExercise:
            return "Cannot edit built-in exercises"
        case .cannotDeleteDefaultExercise:
            return "Cannot delete built-in exercises"
        case .cannotDeleteActiveSplit:
            return "Cannot delete the active split. Please select another split first."
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        }
    }
}

/// Draft model for a workout day being edited
struct DraftWorkoutDay: Identifiable, Equatable {
    let id: UUID
    var name: String
    var dayOrder: Int
    var scheduledWeekdays: [Int]
    var exercises: [DraftPlannedExercise]

    init(
        id: UUID = UUID(),
        name: String = "",
        dayOrder: Int = 0,
        scheduledWeekdays: [Int] = [],
        exercises: [DraftPlannedExercise] = []
    ) {
        self.id = id
        self.name = name
        self.dayOrder = dayOrder
        self.scheduledWeekdays = scheduledWeekdays
        self.exercises = exercises
    }

    init(from workoutDay: WorkoutDay) {
        self.id = workoutDay.id
        self.name = workoutDay.name
        self.dayOrder = workoutDay.dayOrder
        self.scheduledWeekdays = workoutDay.scheduledWeekdays
        self.exercises = workoutDay.sortedExercises.map { DraftPlannedExercise(from: $0) }
    }

    /// Check if this day has valid configuration
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Total sets in this day
    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.targetSets }
    }

    /// Estimated duration in minutes
    var estimatedDuration: Int {
        totalSets * 3
    }
}

/// Draft model for a planned exercise being edited
struct DraftPlannedExercise: Identifiable, Equatable {
    let id: UUID
    var exerciseId: UUID
    var exerciseName: String
    var primaryMuscle: MuscleGroup
    var exerciseOrder: Int
    var targetSets: Int
    var targetRepsMin: Int
    var targetRepsMax: Int
    var restSeconds: Int
    var notes: String?

    init(
        id: UUID = UUID(),
        exerciseId: UUID,
        exerciseName: String,
        primaryMuscle: MuscleGroup,
        exerciseOrder: Int = 0,
        targetSets: Int = WorkoutDefaults.targetSets,
        targetRepsMin: Int = WorkoutDefaults.minReps,
        targetRepsMax: Int = WorkoutDefaults.maxReps,
        restSeconds: Int = WorkoutDefaults.restTimeSeconds,
        notes: String? = nil
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.primaryMuscle = primaryMuscle
        self.exerciseOrder = exerciseOrder
        self.targetSets = targetSets
        self.targetRepsMin = targetRepsMin
        self.targetRepsMax = targetRepsMax
        self.restSeconds = restSeconds
        self.notes = notes
    }

    init(from planned: PlannedExercise) {
        self.id = planned.id
        self.exerciseId = planned.exercise?.id ?? UUID()
        self.exerciseName = planned.exerciseName
        self.primaryMuscle = planned.exercise?.primaryMuscle ?? .chest
        self.exerciseOrder = planned.exerciseOrder
        self.targetSets = planned.targetSets
        self.targetRepsMin = planned.targetRepsMin
        self.targetRepsMax = planned.targetRepsMax
        self.restSeconds = planned.restSeconds
        self.notes = planned.notes
    }

    /// Display string for target reps
    var targetRepsDisplay: String {
        if targetRepsMin == targetRepsMax {
            return "\(targetRepsMin) reps"
        }
        return "\(targetRepsMin)-\(targetRepsMax) reps"
    }

    /// Display string for sets and reps
    var setsAndRepsDisplay: String {
        "\(targetSets) x \(targetRepsDisplay)"
    }
}

/// ViewModel for managing split building operations
@Observable
@MainActor
final class SplitBuilderViewModel {
    // MARK: - Properties

    private var modelContext: ModelContext

    // Split editing state
    var splitName: String = ""
    var splitType: SplitType = .custom
    var workoutDays: [DraftWorkoutDay] = []
    var isEditingExistingSplit: Bool = false
    var editingSplitId: UUID?

    // Day editing state
    var currentDayName: String = ""
    var currentDayExercises: [DraftPlannedExercise] = []
    var currentDayScheduledWeekdays: [Int] = []
    var editingDayIndex: Int?

    // Exercise selection state
    var selectedExercises: Set<UUID> = []
    var searchQuery: String = ""
    var selectedMuscleFilter: MuscleGroup?

    // UI State
    var isLoading: Bool = false
    var showingError: Bool = false
    var errorMessage: String = ""
    var showingDeleteConfirmation: Bool = false
    var showingDiscardConfirmation: Bool = false

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Split Operations

    /// Load an existing split for editing
    func loadSplit(_ split: WorkoutSplit) {
        isEditingExistingSplit = true
        editingSplitId = split.id
        splitName = split.name
        splitType = split.splitType
        workoutDays = split.sortedWorkoutDays.map { DraftWorkoutDay(from: $0) }
    }

    /// Load a template split type with exercises
    func loadTemplate(_ template: SplitType, weekStartDay: WeekStartDay = .monday) {
        isEditingExistingSplit = false
        editingSplitId = nil
        splitName = template.displayName
        splitType = template

        // Get day templates with exercises from SplitTemplateService
        let dayTemplates = SplitTemplateService.shared.getDayTemplates(for: template)
        let exerciseService = ExerciseService.shared

        // Calculate weekday assignments based on number of days and user's week start preference
        let weekdayAssignments = getWeekdayAssignments(for: dayTemplates.count, weekStartDay: weekStartDay)

        workoutDays = dayTemplates.enumerated().map { index, dayTemplate in
            // Fetch exercises for this day
            var draftExercises: [DraftPlannedExercise] = []

            for (exerciseIndex, exerciseName) in dayTemplate.exerciseNames.enumerated() {
                if let exercise = exerciseService.fetchExercise(byName: exerciseName, context: modelContext) {
                    let draftExercise = DraftPlannedExercise(
                        exerciseId: exercise.id,
                        exerciseName: exercise.name,
                        primaryMuscle: exercise.primaryMuscle,
                        exerciseOrder: exerciseIndex,
                        targetSets: exerciseIndex < 2 ? 4 : 3,  // First 2 exercises get 4 sets
                        targetRepsMin: 8,
                        targetRepsMax: 12,
                        restSeconds: exerciseIndex < 2 ? 120 : 90  // Compounds get more rest
                    )
                    draftExercises.append(draftExercise)
                }
            }

            // Assign weekday for this day
            let assignedWeekday = index < weekdayAssignments.count ? [weekdayAssignments[index]] : []

            return DraftWorkoutDay(
                name: dayTemplate.name,
                dayOrder: index,
                scheduledWeekdays: assignedWeekday,
                exercises: draftExercises
            )
        }
    }

    /// Get weekday assignments based on number of workout days and user's week start preference
    /// Returns array of weekday indices (0=Sunday, 1=Monday, ..., 6=Saturday)
    private func getWeekdayAssignments(for dayCount: Int, weekStartDay: WeekStartDay) -> [Int] {
        let firstDayIndex = weekStartDay.firstWeekdayIndex  // Sunday=0, Monday=1

        // Define patterns as offsets from week start
        let offsets: [Int]

        switch dayCount {
        case 3:
            // 3-day: every other day (days 0, 2, 4)
            offsets = [0, 2, 4]
        case 4:
            // 4-day: days 0, 1, 3, 4
            offsets = [0, 1, 3, 4]
        case 5:
            // 5-day: first 5 days
            offsets = [0, 1, 2, 3, 4]
        case 6:
            // 6-day: first 6 days
            offsets = [0, 1, 2, 3, 4, 5]
        case 7:
            // 7-day: every day
            offsets = [0, 1, 2, 3, 4, 5, 6]
        default:
            // For 1-2 days or unknown, use consecutive days from week start
            offsets = Array(0..<min(dayCount, 7))
        }

        // Convert offsets to actual weekday indices
        return offsets.map { (firstDayIndex + $0) % 7 }
    }

    /// Reset to create new split
    func resetForNewSplit() {
        isEditingExistingSplit = false
        editingSplitId = nil
        splitName = ""
        splitType = .custom
        workoutDays = []
        editingDayIndex = nil
        currentDayName = ""
        currentDayExercises = []
    }

    /// Check if current split has valid configuration
    var isSplitValid: Bool {
        !splitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !workoutDays.isEmpty &&
        workoutDays.allSatisfy { $0.isValid }
    }

    /// Check if there are unsaved changes
    var hasUnsavedChanges: Bool {
        if isEditingExistingSplit {
            // TODO: Compare with original
            return true
        }
        return !splitName.isEmpty || !workoutDays.isEmpty
    }

    /// Add a new workout day
    func addWorkoutDay() {
        let newDay = DraftWorkoutDay(
            name: "Day \(workoutDays.count + 1)",
            dayOrder: workoutDays.count,
            scheduledWeekdays: [],
            exercises: []
        )
        workoutDays.append(newDay)
    }

    /// Remove a workout day at index
    func removeWorkoutDay(at index: Int) {
        guard workoutDays.indices.contains(index) else { return }
        workoutDays.remove(at: index)
        // Update day orders
        for i in workoutDays.indices {
            workoutDays[i].dayOrder = i
        }
    }

    /// Move workout days
    func moveWorkoutDays(from source: IndexSet, to destination: Int) {
        workoutDays.move(fromOffsets: source, toOffset: destination)
        // Update day orders
        for i in workoutDays.indices {
            workoutDays[i].dayOrder = i
        }
    }

    /// Start editing a workout day
    func startEditingDay(at index: Int) {
        guard workoutDays.indices.contains(index) else { return }
        editingDayIndex = index
        currentDayName = workoutDays[index].name
        currentDayExercises = workoutDays[index].exercises
        currentDayScheduledWeekdays = workoutDays[index].scheduledWeekdays
    }

    /// Save current day edits
    func saveCurrentDayEdits() {
        guard let index = editingDayIndex, workoutDays.indices.contains(index) else { return }
        workoutDays[index].name = currentDayName
        workoutDays[index].exercises = currentDayExercises
        workoutDays[index].scheduledWeekdays = currentDayScheduledWeekdays
        editingDayIndex = nil
    }

    /// Cancel current day edits
    func cancelDayEdits() {
        editingDayIndex = nil
        currentDayName = ""
        currentDayExercises = []
        currentDayScheduledWeekdays = []
    }

    // MARK: - Exercise Operations for Day

    /// Add exercises to current day
    func addExercisesToCurrentDay(_ exercises: [Exercise]) {
        for exercise in exercises {
            let draft = DraftPlannedExercise(
                exerciseId: exercise.id,
                exerciseName: exercise.name,
                primaryMuscle: exercise.primaryMuscle,
                exerciseOrder: currentDayExercises.count
            )
            currentDayExercises.append(draft)
        }
    }

    /// Remove exercise from current day at index
    func removeExerciseFromCurrentDay(at index: Int) {
        guard currentDayExercises.indices.contains(index) else { return }
        currentDayExercises.remove(at: index)
        // Update orders
        for i in currentDayExercises.indices {
            currentDayExercises[i].exerciseOrder = i
        }
    }

    /// Move exercises in current day
    func moveExercisesInCurrentDay(from source: IndexSet, to destination: Int) {
        currentDayExercises.move(fromOffsets: source, toOffset: destination)
        // Update orders
        for i in currentDayExercises.indices {
            currentDayExercises[i].exerciseOrder = i
        }
    }

    /// Update exercise configuration
    func updateExercise(at index: Int, sets: Int? = nil, repsMin: Int? = nil, repsMax: Int? = nil, rest: Int? = nil, notes: String? = nil) {
        guard currentDayExercises.indices.contains(index) else { return }

        if let sets = sets {
            currentDayExercises[index].targetSets = max(1, min(10, sets))
        }
        if let repsMin = repsMin {
            currentDayExercises[index].targetRepsMin = max(1, min(100, repsMin))
        }
        if let repsMax = repsMax {
            currentDayExercises[index].targetRepsMax = max(1, min(100, repsMax))
        }
        if let rest = rest {
            currentDayExercises[index].restSeconds = max(0, min(600, rest))
        }
        if let notes = notes {
            currentDayExercises[index].notes = notes.isEmpty ? nil : notes
        }
    }

    // MARK: - Save Split

    /// Save the current split configuration
    func saveSplit(for user: User) throws {
        let trimmedName = splitName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            throw SplitBuilderError.emptyName
        }

        guard !workoutDays.isEmpty else {
            throw SplitBuilderError.noWorkoutDays
        }

        if isEditingExistingSplit, let splitId = editingSplitId {
            // Update existing split
            try updateExistingSplit(id: splitId, name: trimmedName, user: user)
        } else {
            // Create new split
            try createNewSplit(name: trimmedName, user: user)
        }
    }

    private func createNewSplit(name: String, user: User) throws {
        // Deactivate other splits if this will be active
        for split in user.workoutSplits {
            split.isActive = false
        }

        let newSplit = WorkoutSplit(
            name: name,
            splitType: splitType,
            isActive: true
        )
        newSplit.user = user
        modelContext.insert(newSplit)

        // Create workout days
        for draftDay in workoutDays {
            let workoutDay = WorkoutDay(
                id: draftDay.id,
                name: draftDay.name,
                dayOrder: draftDay.dayOrder,
                scheduledWeekdays: draftDay.scheduledWeekdays
            )
            workoutDay.split = newSplit
            modelContext.insert(workoutDay)

            // Create planned exercises
            for draftExercise in draftDay.exercises {
                // Find the actual exercise
                let exerciseId = draftExercise.exerciseId
                let descriptor = FetchDescriptor<Exercise>(
                    predicate: #Predicate<Exercise> { $0.id == exerciseId }
                )
                guard let exercise = try? modelContext.fetch(descriptor).first else { continue }

                let planned = PlannedExercise(
                    id: draftExercise.id,
                    exerciseOrder: draftExercise.exerciseOrder,
                    targetSets: draftExercise.targetSets,
                    targetRepsMin: draftExercise.targetRepsMin,
                    targetRepsMax: draftExercise.targetRepsMax,
                    restSeconds: draftExercise.restSeconds,
                    notes: draftExercise.notes
                )
                planned.workoutDay = workoutDay
                planned.exercise = exercise
                modelContext.insert(planned)
            }
        }

        do {
            try modelContext.save()
        } catch {
            throw SplitBuilderError.saveFailed(error)
        }

        // Refresh widgets with new split data
        WidgetUpdateService.reloadAllTimelines()
    }

    private func updateExistingSplit(id: UUID, name: String, user: User) throws {
        let descriptor = FetchDescriptor<WorkoutSplit>(
            predicate: #Predicate<WorkoutSplit> { $0.id == id }
        )
        guard let split = try? modelContext.fetch(descriptor).first else { return }

        split.name = name
        split.splitType = splitType

        // Delete existing workout days (cascade will delete planned exercises)
        for day in split.workoutDays {
            modelContext.delete(day)
        }

        // Create new workout days
        for draftDay in workoutDays {
            let workoutDay = WorkoutDay(
                name: draftDay.name,
                dayOrder: draftDay.dayOrder,
                scheduledWeekdays: draftDay.scheduledWeekdays
            )
            workoutDay.split = split
            modelContext.insert(workoutDay)

            // Create planned exercises
            for draftExercise in draftDay.exercises {
                let exerciseId = draftExercise.exerciseId
                let descriptor = FetchDescriptor<Exercise>(
                    predicate: #Predicate<Exercise> { $0.id == exerciseId }
                )
                guard let exercise = try? modelContext.fetch(descriptor).first else { continue }

                let planned = PlannedExercise(
                    exerciseOrder: draftExercise.exerciseOrder,
                    targetSets: draftExercise.targetSets,
                    targetRepsMin: draftExercise.targetRepsMin,
                    targetRepsMax: draftExercise.targetRepsMax,
                    restSeconds: draftExercise.restSeconds,
                    notes: draftExercise.notes
                )
                planned.workoutDay = workoutDay
                planned.exercise = exercise
                modelContext.insert(planned)
            }
        }

        do {
            try modelContext.save()
        } catch {
            throw SplitBuilderError.saveFailed(error)
        }

        // Refresh widgets with updated split data
        WidgetUpdateService.reloadAllTimelines()
    }

    // MARK: - Split List Operations

    /// Set a split as active
    func setActiveSplit(_ split: WorkoutSplit, user: User) {
        // Deactivate all splits
        for s in user.workoutSplits {
            s.isActive = false
        }

        // Activate selected split
        split.isActive = true

        try? modelContext.save()

        // Refresh widgets with new active split
        WidgetUpdateService.reloadAllTimelines()
    }

    /// Delete a split
    func deleteSplit(_ split: WorkoutSplit) throws {
        if split.isActive {
            throw SplitBuilderError.cannotDeleteActiveSplit
        }

        modelContext.delete(split)
        try modelContext.save()
    }

    // MARK: - Exercise Filtering

    /// Filter exercises by search and muscle group
    func filterExercises(_ exercises: [Exercise]) -> [Exercise] {
        var filtered = exercises

        // Filter by muscle group
        if let muscle = selectedMuscleFilter {
            filtered = filtered.filter { $0.primaryMuscle == muscle }
        }

        // Filter by search query
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            filtered = filtered.filter { $0.name.lowercased().contains(query) }
        }

        return filtered.sorted { $0.name < $1.name }
    }

    /// Group exercises by muscle group
    func groupExercisesByMuscle(_ exercises: [Exercise]) -> [(MuscleGroup, [Exercise])] {
        let grouped = Dictionary(grouping: exercises) { $0.primaryMuscle }
        return MuscleGroup.allCases.compactMap { muscle in
            guard let exercises = grouped[muscle], !exercises.isEmpty else { return nil }
            return (muscle, exercises.sorted { $0.name < $1.name })
        }
    }

    // MARK: - Error Handling

    func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}
