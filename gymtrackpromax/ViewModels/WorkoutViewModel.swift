//
//  WorkoutViewModel.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import ActivityKit
import Foundation
import SwiftData
import SwiftUI
import WidgetKit

/// ViewModel for managing active workout state
@Observable
@MainActor
final class WorkoutViewModel {
    // MARK: - Session State

    /// Current workout session
    var currentSession: WorkoutSession?

    /// Start time for elapsed time calculation (used by TimelineView in ActiveWorkoutView)
    var workoutStartTime: Date?

    /// Compute elapsed time display from start time
    static func formatElapsedTime(from startTime: Date?) -> String {
        guard let startTime else { return "00:00" }
        let elapsed = Int(Date().timeIntervalSince(startTime))
        let hours = elapsed / 3600
        let minutes = (elapsed % 3600) / 60
        let seconds = elapsed % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Exercise Navigation

    /// Index of current exercise
    var currentExerciseIndex: Int = 0

    /// All exercise logs for this session
    var exerciseLogs: [ExerciseLog] {
        currentSession?.sortedExerciseLogs ?? []
    }

    /// Current exercise log
    var currentExerciseLog: ExerciseLog? {
        guard currentExerciseIndex < exerciseLogs.count else { return nil }
        return exerciseLogs[currentExerciseIndex]
    }

    /// Current planned exercise
    var currentPlannedExercise: PlannedExercise? {
        guard let workoutDay = currentSession?.workoutDay,
              currentExerciseIndex < workoutDay.sortedExercises.count else { return nil }
        return workoutDay.sortedExercises[currentExerciseIndex]
    }

    /// Next planned exercise (for preview)
    var nextPlannedExercise: PlannedExercise? {
        guard let workoutDay = currentSession?.workoutDay,
              currentExerciseIndex + 1 < workoutDay.sortedExercises.count else { return nil }
        return workoutDay.sortedExercises[currentExerciseIndex + 1]
    }

    /// Whether we're on the last exercise
    var isOnLastExercise: Bool {
        guard let workoutDay = currentSession?.workoutDay else { return true }
        return currentExerciseIndex >= workoutDay.sortedExercises.count - 1
    }

    /// Whether there's a previous exercise
    var hasPreviousExercise: Bool {
        currentExerciseIndex > 0
    }

    // MARK: - Superset State

    /// Whether the current exercise is part of a superset
    var isCurrentExerciseInSuperset: Bool {
        currentExerciseLog?.isInSuperset ?? false
    }

    /// The superset group ID for the current exercise (nil if standalone)
    var currentSupersetGroupId: UUID? {
        currentExerciseLog?.supersetGroupId
    }

    /// All exercise logs in the current superset group
    var currentSupersetLogs: [ExerciseLog] {
        guard let groupId = currentSupersetGroupId else { return [] }
        return exerciseLogs
            .filter { $0.supersetGroupId == groupId }
            .sorted { $0.supersetOrder < $1.supersetOrder }
    }

    /// Position of current exercise within its superset (1-based)
    var supersetPosition: Int {
        guard let groupId = currentSupersetGroupId else { return 0 }
        let group = currentSupersetLogs
        guard let currentId = currentExerciseLog?.id else { return 0 }
        return (group.firstIndex(where: { $0.id == currentId }) ?? 0) + 1
    }

    /// Total exercises in current superset
    var supersetSize: Int {
        currentSupersetLogs.count
    }

    /// Display string for superset position (e.g., "Superset 1/2")
    var supersetPositionDisplay: String? {
        guard isCurrentExerciseInSuperset else { return nil }
        return "Superset \(supersetPosition)/\(supersetSize)"
    }

    /// Whether the current exercise is the last in its superset group
    private var isLastInSuperset: Bool {
        supersetPosition >= supersetSize
    }

    /// Next exercise log in the superset group (nil if last or not in superset)
    private var nextSupersetExerciseIndex: Int? {
        guard let groupId = currentSupersetGroupId else { return nil }
        let group = currentSupersetLogs
        guard let currentId = currentExerciseLog?.id,
              let currentPos = group.firstIndex(where: { $0.id == currentId }),
              currentPos + 1 < group.count else { return nil }

        let nextLog = group[currentPos + 1]
        return exerciseLogs.firstIndex(where: { $0.id == nextLog.id })
    }

    // MARK: - Set Input State

    /// Weight for pending set
    var pendingWeight: Double = 0

    /// Reps for pending set
    var pendingReps: Int = 8

    /// Duration for pending set (in seconds, for timed exercises)
    var pendingDuration: Int = 30

    /// RPE for pending set (optional)
    var pendingRPE: Int? = nil

    /// Whether pending set is a warmup
    var isWarmupSet: Bool = false

    /// Whether pending set is a dropset
    var isDropset: Bool = false

    // MARK: - Timer

    /// Timer service
    var timerService = TimerService()

    /// Whether to show rest timer overlay
    var showRestTimerOverlay: Bool = false

    /// Default rest time in seconds
    var defaultRestTime: TimeInterval {
        TimeInterval(currentPlannedExercise?.restSeconds ?? WorkoutDefaults.restTimeSeconds)
    }

    // MARK: - PRs

    /// PRs achieved during this workout
    var achievedPRs: [PRInfo] = []

    /// Most recent PR (for display)
    var latestPR: PRInfo? {
        achievedPRs.last
    }

    // MARK: - Sheets & Dialogs

    /// Whether to show exercise list sheet
    var showExerciseListSheet: Bool = false

    /// Whether to show abandon confirmation
    var showAbandonConfirmation: Bool = false

    /// Whether workout is completed
    var isWorkoutCompleted: Bool = false

    // MARK: - Computed Workout State

    /// Whether any sets have been logged in this session
    var hasLoggedSets: Bool {
        guard let session = currentSession else { return false }
        return session.exerciseLogs.contains { !$0.sets.isEmpty }
    }

    /// Total number of sets logged across all exercises
    var loggedSetsCount: Int {
        guard let session = currentSession else { return 0 }
        return session.exerciseLogs.reduce(0) { $0 + $1.sets.count }
    }

    // MARK: - Private Properties

    private var modelContext: ModelContext
    private var workoutService = WorkoutService.shared
    private var restTimerObserver: Any?
    private var dayEditedObserver: Any?
    private var watchStartedObserver: Any?
    private var watchSetLoggedObserver: Any?
    private var watchCompletedObserver: Any?

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        observeWatchEvents()
    }

    deinit {
        let center = NotificationCenter.default
        center.removeObserver(self)
    }

    // MARK: - Workout Actions

    /// Start a new workout
    func startWorkout(workoutDay: WorkoutDay, user: User) {
        currentSession = workoutService.startWorkout(
            workoutDay: workoutDay,
            user: user,
            context: modelContext
        )

        currentExerciseIndex = 0
        workoutStartTime = currentSession?.startTime ?? Date()
        achievedPRs = []
        isWorkoutCompleted = false

        // Initialize set input with suggested values
        initializeSetInput()

        // Start Live Activity
        startLiveActivity()

        // Observe rest timer completion to clear Live Activity rest state
        observeRestTimerCompletion()

        // Observe workout day edits to sync session
        observeDayEdits()

        // Request notification permission
        Task {
            _ = await timerService.requestNotificationPermission()
        }
    }

    /// Resume an existing workout session
    func resumeWorkout(session: WorkoutSession) {
        currentSession = session
        currentExerciseIndex = 0
        achievedPRs = []
        isWorkoutCompleted = false

        // Store start time for TimelineView-based elapsed display
        workoutStartTime = session.startTime

        // Initialize set input
        initializeSetInput()

        // Start Live Activity
        startLiveActivity()

        // Observe rest timer completion
        observeRestTimerCompletion()

        // Observe workout day edits
        observeDayEdits()
    }

    /// Complete the workout
    func completeWorkout(notes: String? = nil) {
        guard let session = currentSession else { return }

        timerService.stop()

        workoutService.endWorkout(
            session: session,
            notes: notes,
            context: modelContext
        )

        isWorkoutCompleted = true

        // End Live Activity
        LiveActivityService.shared.endActivity()
        removeRestTimerObserver()
        removeDayEditedObserver()

        // Refresh widgets with updated data
        WidgetUpdateService.reloadAllTimelines()

        // Index completed workout in Spotlight
        SpotlightService.shared.indexWorkoutSession(session)

        // Haptic feedback
        HapticManager.workoutComplete()
    }

    /// Abandon the workout
    func abandonWorkout(saveProgress: Bool) {
        guard let session = currentSession else { return }

        timerService.stop()

        workoutService.abandonWorkout(
            session: session,
            saveProgress: saveProgress,
            context: modelContext
        )

        // End Live Activity
        LiveActivityService.shared.endActivity()
        removeRestTimerObserver()
        removeDayEditedObserver()

        currentSession = nil
    }

    // MARK: - Set Actions

    /// Log the current pending set
    func logSet() {
        guard let exerciseLog = currentExerciseLog else { return }

        // Determine duration based on exercise type
        let exerciseType = exerciseLog.exercise?.exerciseType ?? .weightAndReps
        let durationToLog: Int? = exerciseType.showsDuration ? pendingDuration : nil

        let setLog = workoutService.logSet(
            exerciseLog: exerciseLog,
            weight: pendingWeight,
            reps: pendingReps,
            duration: durationToLog,
            rpe: pendingRPE,
            isWarmup: isWarmupSet,
            isDropset: isDropset,
            context: modelContext
        )

        // Check for PR
        if let exercise = exerciseLog.exercise,
           let user = currentSession?.user {
            if let pr = workoutService.checkForPR(
                exercise: exercise,
                newSet: setLog,
                user: user,
                context: modelContext
            ) {
                achievedPRs.append(pr)

                // Double haptic for PR
                HapticManager.prAchieved()
            } else {
                // Normal haptic for set logged
                HapticManager.setLogged()
            }
        }

        // Reset warmup/dropset flags
        isWarmupSet = false
        isDropset = false

        // Superset auto-advance logic
        if isCurrentExerciseInSuperset && !setLog.isWarmup {
            if let nextIndex = nextSupersetExerciseIndex {
                // Advance to next exercise in superset (short/no rest)
                currentExerciseIndex = nextIndex
                initializeSetInput()
                updateLiveActivity()
                HapticManager.buttonTap()
            } else {
                // Completed a round of the superset — full rest
                // Go back to first exercise in superset for next round
                if let firstLog = currentSupersetLogs.first,
                   let firstIndex = exerciseLogs.firstIndex(where: { $0.id == firstLog.id }) {
                    currentExerciseIndex = firstIndex
                    initializeSetInput()
                }
                startRestTimer()
                updateLiveActivity()
            }
        } else {
            // Normal (non-superset) behavior
            if !setLog.isWarmup {
                startRestTimer()
            }
            updateLiveActivity()
        }
    }

    /// Delete a set
    func deleteSet(_ set: SetLog) {
        workoutService.deleteSet(set: set, context: modelContext)

        // Remove any PR associated with this set if applicable
        achievedPRs.removeAll { pr in
            pr.value == set.estimated1RM && pr.exerciseName == currentExerciseLog?.exerciseName
        }
    }

    /// Update set input from a completed set (for editing)
    func editSet(_ set: SetLog) {
        pendingWeight = set.weight
        pendingReps = set.reps
        if let duration = set.duration {
            pendingDuration = duration
        }
        pendingRPE = set.rpe
        isWarmupSet = set.isWarmup
        isDropset = set.isDropset
    }

    /// Duplicate the last logged set values
    func duplicateLastSet() {
        guard let lastSet = currentExerciseLog?.sortedSets.last else { return }
        pendingWeight = lastSet.weight
        pendingReps = lastSet.reps
        if let duration = lastSet.duration {
            pendingDuration = duration
        }
        pendingRPE = lastSet.rpe
        // Don't copy warmup/dropset flags - user likely wants a working set
        HapticManager.buttonTap()
    }

    /// Whether there are sets to duplicate
    var canDuplicateLastSet: Bool {
        guard let sets = currentExerciseLog?.sets else { return false }
        return !sets.isEmpty
    }

    /// Update notes for current exercise
    func updateExerciseNotes(_ notes: String) {
        currentExerciseLog?.notes = notes.isEmpty ? nil : notes
    }

    // MARK: - Exercise Navigation

    /// Move to next exercise
    func nextExercise() {
        guard !isOnLastExercise else { return }

        currentExerciseIndex += 1
        initializeSetInput()
        updateLiveActivity()

        // Light haptic
        HapticManager.buttonTap()
    }

    /// Move to previous exercise
    func previousExercise() {
        guard hasPreviousExercise else { return }

        currentExerciseIndex -= 1
        initializeSetInput()
        updateLiveActivity()

        // Light haptic
        HapticManager.buttonTap()
    }

    /// Jump to specific exercise
    func goToExercise(at index: Int) {
        guard index >= 0 && index < exerciseLogs.count else { return }

        currentExerciseIndex = index
        initializeSetInput()
        showExerciseListSheet = false
        updateLiveActivity()

        // Light haptic
        HapticManager.buttonTap()
    }

    /// Reorder exercises in the active workout
    func reorderExercises(from source: IndexSet, to destination: Int) {
        guard let session = currentSession else { return }

        var logs = session.sortedExerciseLogs
        logs.move(fromOffsets: source, toOffset: destination)

        // Update exercise order on each log
        for (index, log) in logs.enumerated() {
            log.exerciseOrder = index
        }

        try? modelContext.save()

        // Adjust current index if needed
        if let oldIndex = source.first {
            if oldIndex == currentExerciseIndex {
                currentExerciseIndex = oldIndex < destination ? destination - 1 : destination
            } else if oldIndex < currentExerciseIndex && destination > currentExerciseIndex {
                currentExerciseIndex -= 1
            } else if oldIndex > currentExerciseIndex && destination <= currentExerciseIndex {
                currentExerciseIndex += 1
            }
        }

        HapticManager.buttonTap()
    }

    // MARK: - Timer Actions

    /// Start the rest timer
    func startRestTimer() {
        timerService.start(duration: defaultRestTime)
        showRestTimerOverlay = true

        // Update Live Activity with rest timer
        LiveActivityService.shared.startRestTimer(
            currentState: buildCurrentContentState(),
            restDuration: defaultRestTime
        )
    }

    /// Skip the rest timer
    func skipRestTimer() {
        timerService.skip()
        showRestTimerOverlay = false

        // Clear rest timer from Live Activity
        LiveActivityService.shared.clearRestTimer(
            currentState: buildCurrentContentState()
        )
    }

    /// Dismiss the rest timer overlay
    func dismissRestTimerOverlay() {
        showRestTimerOverlay = false
    }

    // MARK: - Weight/Reps Adjustment

    /// Increment weight
    func incrementWeight() {
        let increment = currentExerciseLog?.exercise?.weightIncrement ?? WorkoutDefaults.weightIncrementKg
        pendingWeight += increment

        HapticManager.lightImpact()
    }

    /// Decrement weight
    func decrementWeight() {
        let increment = currentExerciseLog?.exercise?.weightIncrement ?? WorkoutDefaults.weightIncrementKg
        pendingWeight = max(0, pendingWeight - increment)

        HapticManager.lightImpact()
    }

    /// Increment reps
    func incrementReps() {
        pendingReps += 1

        HapticManager.lightImpact()
    }

    /// Decrement reps
    func decrementReps() {
        pendingReps = max(1, pendingReps - 1)

        HapticManager.lightImpact()
    }

    // MARK: - Previous Session Data

    /// Get previous performance string for current exercise
    var previousPerformanceDisplay: String? {
        guard let exercise = currentExerciseLog?.exercise,
              let workoutDay = currentSession?.workoutDay else { return nil }

        return workoutService.getPreviousSetsDisplay(
            exercise: exercise,
            workoutDay: workoutDay,
            context: modelContext
        )
    }

    // MARK: - Private Methods

    // MARK: - Live Activity Helpers

    private func buildCurrentContentState() -> WorkoutActivityAttributes.ContentState {
        let exerciseLog = currentExerciseLog
        let exerciseName = exerciseLog?.exerciseName ?? "Exercise"
        let muscleGroup = exerciseLog?.exercise?.primaryMuscle.displayName ?? "Muscle"
        let setsCompleted = exerciseLog?.sets.count ?? 0
        let targetSets = currentPlannedExercise?.targetSets ?? 4
        let totalSetsLogged = exerciseLogs.reduce(0) { $0 + $1.sets.count }

        return WorkoutActivityAttributes.ContentState(
            currentExerciseName: exerciseName,
            currentMuscleGroup: muscleGroup,
            setsCompleted: setsCompleted,
            targetSets: targetSets,
            currentExerciseNumber: currentExerciseIndex + 1,
            totalSetsLogged: totalSetsLogged,
            isResting: false,
            restTimerStart: nil,
            restTimerEnd: nil
        )
    }

    private func updateLiveActivity() {
        let state = buildCurrentContentState()
        LiveActivityService.shared.updateActivity(state: state)
    }

    /// Send current workout state to the Watch
    private func syncStateToWatch() {
        PhoneConnectivityService.shared.sendWorkoutState()
    }

    private func startLiveActivity() {
        guard let session = currentSession,
              let workoutDay = session.workoutDay else { return }

        let workoutName = workoutDay.name
        let totalExercises = workoutDay.sortedExercises.count
        let initialState = buildCurrentContentState()

        LiveActivityService.shared.startActivity(
            workoutName: workoutName,
            startTime: session.startTime,
            totalExercises: totalExercises,
            initialState: initialState
        )
    }

    private func observeRestTimerCompletion() {
        removeRestTimerObserver()
        restTimerObserver = NotificationCenter.default.addObserver(
            forName: .restTimerCompleted,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                LiveActivityService.shared.clearRestTimer(
                    currentState: self.buildCurrentContentState()
                )
            }
        }
    }

    private func removeRestTimerObserver() {
        if let observer = restTimerObserver {
            NotificationCenter.default.removeObserver(observer)
            restTimerObserver = nil
        }
    }

    private func observeDayEdits() {
        removeDayEditedObserver()
        dayEditedObserver = NotificationCenter.default.addObserver(
            forName: .workoutDayEdited,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                // Clamp exercise index if exercises were removed
                let logCount = self.exerciseLogs.count
                if logCount > 0 && self.currentExerciseIndex >= logCount {
                    self.currentExerciseIndex = logCount - 1
                }
                self.initializeSetInput()
                self.updateLiveActivity()
            }
        }
    }

    private func removeDayEditedObserver() {
        if let observer = dayEditedObserver {
            NotificationCenter.default.removeObserver(observer)
            dayEditedObserver = nil
        }
    }

    private func initializeSetInput() {
        guard let exercise = currentExerciseLog?.exercise,
              let user = currentSession?.user else {
            pendingWeight = 0
            pendingReps = 8
            return
        }

        // Suggest weight from history
        if let suggestedWeight = workoutService.suggestWeight(
            for: exercise,
            user: user,
            context: modelContext
        ) {
            pendingWeight = suggestedWeight
        } else {
            pendingWeight = 0
        }

        // Suggest reps from planned exercise
        if let planned = currentPlannedExercise {
            pendingReps = workoutService.suggestReps(for: planned)
        } else {
            pendingReps = 8
        }

        // Reset other values
        pendingDuration = 30
        pendingRPE = nil
        isWarmupSet = false
        isDropset = false
    }

    // MARK: - Watch Event Observers

    private func observeWatchEvents() {
        // Observe workout started from Watch
        watchStartedObserver = NotificationCenter.default.addObserver(
            forName: .workoutStartedFromWatch,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let session = notification.object as? WorkoutSession else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                // Resume the workout that was started from Watch
                self.resumeWorkout(session: session)
            }
        }

        // Observe set logged from Watch
        watchSetLoggedObserver = NotificationCenter.default.addObserver(
            forName: .setLoggedFromWatch,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                // Refresh UI to show the new set
                // The set is already logged, just need to update Live Activity
                self.updateLiveActivity()
            }
        }

        // Observe workout completed from Watch
        watchCompletedObserver = NotificationCenter.default.addObserver(
            forName: .workoutCompletedFromWatch,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                // Mark workout as completed in UI
                self.isWorkoutCompleted = true
                self.timerService.stop()
                LiveActivityService.shared.endActivity()
                self.removeRestTimerObserver()
                self.removeDayEditedObserver()
                WidgetUpdateService.reloadAllTimelines()
            }
        }
    }

    private func removeWatchObservers() {
        if let observer = watchStartedObserver {
            NotificationCenter.default.removeObserver(observer)
            watchStartedObserver = nil
        }
        if let observer = watchSetLoggedObserver {
            NotificationCenter.default.removeObserver(observer)
            watchSetLoggedObserver = nil
        }
        if let observer = watchCompletedObserver {
            NotificationCenter.default.removeObserver(observer)
            watchCompletedObserver = nil
        }
    }
}
