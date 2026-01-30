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

    /// Elapsed time since workout started
    var elapsedTime: TimeInterval = 0

    /// Formatted elapsed time string
    var elapsedTimeDisplay: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60

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

    // MARK: - Private Properties

    private var modelContext: ModelContext
    private var workoutService = WorkoutService.shared
    private var elapsedTimer: Timer?
    private var restTimerObserver: Any?

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
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
        elapsedTime = 0
        achievedPRs = []
        isWorkoutCompleted = false

        // Initialize set input with suggested values
        initializeSetInput()

        // Start elapsed time timer
        startElapsedTimer()

        // Start Live Activity
        startLiveActivity()

        // Observe rest timer completion to clear Live Activity rest state
        observeRestTimerCompletion()

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

        // Calculate elapsed time since start
        elapsedTime = Date().timeIntervalSince(session.startTime)

        // Initialize set input
        initializeSetInput()

        // Start elapsed time timer
        startElapsedTimer()

        // Start Live Activity
        startLiveActivity()

        // Observe rest timer completion
        observeRestTimerCompletion()
    }

    /// Complete the workout
    func completeWorkout(notes: String? = nil) {
        guard let session = currentSession else { return }

        elapsedTimer?.invalidate()
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

        // Refresh widgets with updated data
        WidgetUpdateService.reloadAllTimelines()

        // Haptic feedback
        HapticManager.workoutComplete()
    }

    /// Abandon the workout
    func abandonWorkout(saveProgress: Bool) {
        guard let session = currentSession else { return }

        elapsedTimer?.invalidate()
        timerService.stop()

        workoutService.abandonWorkout(
            session: session,
            saveProgress: saveProgress,
            context: modelContext
        )

        // End Live Activity
        LiveActivityService.shared.endActivity()
        removeRestTimerObserver()

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

        // Auto-start rest timer if not a warmup
        if !setLog.isWarmup {
            startRestTimer()
        }

        // Update Live Activity (rest timer update handled in startRestTimer)
        updateLiveActivity()
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

    private func startElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.elapsedTime += 1
            }
        }
    }

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
}
