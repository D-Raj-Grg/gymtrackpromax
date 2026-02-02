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

/// Info about an exercise that would lose logged sets if removed
struct PendingExerciseRemoval: Identifiable {
    let id = UUID()
    let exerciseName: String
    let loggedSetsCount: Int
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

    // In-progress session conflict state
    var pendingRemovals: [PendingExerciseRemoval] = []
    var showingInProgressConflictAlert: Bool = false
    private var pendingSaveUser: User?

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

    /// Computed message for the conflict alert
    var conflictAlertMessage: String {
        let lines = pendingRemovals.map { "\($0.exerciseName) — \($0.loggedSetsCount) set\($0.loggedSetsCount == 1 ? "" : "s") logged" }
        return "The following exercises have logged progress in an active workout:\n\n" + lines.joined(separator: "\n") + "\n\nRemoving them will delete that progress."
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
            // Check for in-progress session conflicts before updating
            let removals = analyzeInProgressSessionConflicts(splitId: splitId)
            if !removals.isEmpty {
                pendingRemovals = removals
                pendingSaveUser = user
                showingInProgressConflictAlert = true
                return
            }
            // No conflicts, proceed normally
            try updateExistingSplit(id: splitId, name: trimmedName, user: user)
        } else {
            // Create new split
            try createNewSplit(name: trimmedName, user: user)
        }
    }

    /// Called after user confirms removal of exercises with progress
    func confirmAndSaveSplit() throws {
        guard let user = pendingSaveUser, let splitId = editingSplitId else { return }
        let trimmedName = splitName.trimmingCharacters(in: .whitespacesAndNewlines)
        pendingRemovals = []
        pendingSaveUser = nil
        try updateExistingSplit(id: splitId, name: trimmedName, user: user)
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

        let existingDays = split.workoutDays
        let existingDayById = Dictionary(uniqueKeysWithValues: existingDays.map { ($0.id, $0) })
        let draftDayIds = Set(workoutDays.map { $0.id })
        var sessionsSynced = false

        // Remove days that are no longer in the draft
        for day in existingDays where !draftDayIds.contains(day.id) {
            modelContext.delete(day)
        }

        // Update or create days
        for draftDay in workoutDays {
            if let existingDay = existingDayById[draftDay.id] {
                // Update existing day in place
                existingDay.name = draftDay.name
                existingDay.dayOrder = draftDay.dayOrder
                existingDay.scheduledWeekdays = draftDay.scheduledWeekdays

                // Sync in-progress session if one exists
                if let session = existingDay.inProgressSession {
                    syncSessionExerciseLogs(session: session, with: draftDay)
                    sessionsSynced = true
                }

                // Replace planned exercises
                for planned in existingDay.plannedExercises {
                    modelContext.delete(planned)
                }
                createPlannedExercises(for: existingDay, from: draftDay)
            } else {
                // Create new day
                let workoutDay = WorkoutDay(
                    id: draftDay.id,
                    name: draftDay.name,
                    dayOrder: draftDay.dayOrder,
                    scheduledWeekdays: draftDay.scheduledWeekdays
                )
                workoutDay.split = split
                modelContext.insert(workoutDay)
                createPlannedExercises(for: workoutDay, from: draftDay)
            }
        }

        do {
            try modelContext.save()
        } catch {
            throw SplitBuilderError.saveFailed(error)
        }

        if sessionsSynced {
            NotificationCenter.default.post(name: .workoutDayEdited, object: nil)
        }

        // Refresh widgets with updated split data
        WidgetUpdateService.reloadAllTimelines()
    }

    // MARK: - In-Progress Session Helpers

    /// Analyze which exercises with logged sets would be removed
    private func analyzeInProgressSessionConflicts(splitId: UUID) -> [PendingExerciseRemoval] {
        let descriptor = FetchDescriptor<WorkoutSplit>(
            predicate: #Predicate<WorkoutSplit> { $0.id == splitId }
        )
        guard let split = try? modelContext.fetch(descriptor).first else { return [] }

        var removals: [PendingExerciseRemoval] = []

        for draftDay in workoutDays {
            // Find the matching existing day by ID
            guard let existingDay = split.workoutDays.first(where: { $0.id == draftDay.id }),
                  let session = existingDay.inProgressSession else { continue }

            let draftExerciseIds = Set(draftDay.exercises.map { $0.exerciseId })

            for log in session.exerciseLogs {
                guard let exerciseId = log.exercise?.id else { continue }
                if !draftExerciseIds.contains(exerciseId) && !log.sets.isEmpty {
                    removals.append(PendingExerciseRemoval(
                        exerciseName: log.exerciseName,
                        loggedSetsCount: log.sets.count
                    ))
                }
            }
        }

        return removals
    }

    /// Sync an in-progress session's ExerciseLogs with the edited draft day
    private func syncSessionExerciseLogs(session: WorkoutSession, with draftDay: DraftWorkoutDay) {
        // Map existing logs by exercise ID
        var logsByExerciseId: [UUID: ExerciseLog] = [:]
        for log in session.exerciseLogs {
            if let exerciseId = log.exercise?.id {
                logsByExerciseId[exerciseId] = log
            }
        }

        let draftExerciseIds = Set(draftDay.exercises.map { $0.exerciseId })

        // Remove logs for exercises no longer in the draft
        for log in session.exerciseLogs {
            if let exerciseId = log.exercise?.id, !draftExerciseIds.contains(exerciseId) {
                modelContext.delete(log)
            }
        }

        // Update order on kept logs and create new logs for added exercises
        for draftExercise in draftDay.exercises {
            if let existingLog = logsByExerciseId[draftExercise.exerciseId] {
                // Update order
                existingLog.exerciseOrder = draftExercise.exerciseOrder
            } else {
                // Create new empty log for newly added exercise
                let exerciseId = draftExercise.exerciseId
                let exerciseDescriptor = FetchDescriptor<Exercise>(
                    predicate: #Predicate<Exercise> { $0.id == exerciseId }
                )
                guard let exercise = try? modelContext.fetch(exerciseDescriptor).first else { continue }

                let newLog = ExerciseLog(exerciseOrder: draftExercise.exerciseOrder)
                newLog.exercise = exercise
                newLog.session = session
                session.exerciseLogs.append(newLog)
                modelContext.insert(newLog)
            }
        }
    }

    /// Create PlannedExercises for a WorkoutDay from a draft
    private func createPlannedExercises(for workoutDay: WorkoutDay, from draftDay: DraftWorkoutDay) {
        for draftExercise in draftDay.exercises {
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
