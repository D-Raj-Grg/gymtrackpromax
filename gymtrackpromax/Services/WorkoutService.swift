//
//  WorkoutService.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import Foundation
import SwiftData

/// Information about a personal record achievement
struct PRInfo: Identifiable, Equatable {
    let id: UUID
    let exerciseName: String
    let type: PRType
    let value: Double
    let previousValue: Double?
    let improvement: Double
    let timestamp: Date

    init(
        id: UUID = UUID(),
        exerciseName: String,
        type: PRType,
        value: Double,
        previousValue: Double? = nil,
        improvement: Double,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.exerciseName = exerciseName
        self.type = type
        self.value = value
        self.previousValue = previousValue
        self.improvement = improvement
        self.timestamp = timestamp
    }
}

/// Type of personal record
enum PRType: String, Codable {
    case estimated1RM
    case maxWeight
    case maxReps
    case maxVolume

    var displayName: String {
        switch self {
        case .estimated1RM:
            return "Estimated 1RM"
        case .maxWeight:
            return "Max Weight"
        case .maxReps:
            return "Max Reps"
        case .maxVolume:
            return "Max Volume"
        }
    }
}

/// Service for managing workout sessions
@MainActor
final class WorkoutService {
    // MARK: - Singleton

    static let shared = WorkoutService()

    private init() {}

    // MARK: - Session Management

    /// Start a new workout session
    func startWorkout(
        workoutDay: WorkoutDay,
        user: User,
        context: ModelContext
    ) -> WorkoutSession {
        let session = WorkoutSession(
            startTime: Date()
        )
        session.workoutDay = workoutDay
        session.user = user

        // Create exercise logs for each planned exercise
        for (index, plannedExercise) in workoutDay.sortedExercises.enumerated() {
            let exerciseLog = ExerciseLog(exerciseOrder: index)
            exerciseLog.exercise = plannedExercise.exercise
            exerciseLog.session = session
            session.exerciseLogs.append(exerciseLog)
            context.insert(exerciseLog)
        }

        context.insert(session)

        // Post notification
        NotificationCenter.default.post(name: .workoutStarted, object: session)

        return session
    }

    /// End a workout session
    func endWorkout(
        session: WorkoutSession,
        notes: String?,
        context: ModelContext
    ) {
        session.endTime = Date()
        session.notes = notes

        try? context.save()

        // Post notification
        NotificationCenter.default.post(name: .workoutCompleted, object: session)
    }

    /// Abandon a workout session
    func abandonWorkout(
        session: WorkoutSession,
        saveProgress: Bool,
        context: ModelContext
    ) {
        if saveProgress {
            // Keep session but mark as incomplete
            // endTime stays nil to indicate abandoned/in-progress
            try? context.save()
        } else {
            // Delete session and all logs
            context.delete(session)
            try? context.save()
        }
    }

    // MARK: - Set Logging

    /// Log a new set
    func logSet(
        exerciseLog: ExerciseLog,
        weight: Double,
        reps: Int,
        duration: Int?,
        rpe: Int?,
        isWarmup: Bool,
        isDropset: Bool,
        context: ModelContext
    ) -> SetLog {
        let setNumber = exerciseLog.sets.count + 1

        let setLog = SetLog(
            setNumber: setNumber,
            weight: weight,
            reps: reps,
            duration: duration,
            rpe: rpe,
            isWarmup: isWarmup,
            isDropset: isDropset
        )

        setLog.exerciseLog = exerciseLog
        exerciseLog.sets.append(setLog)

        context.insert(setLog)
        try? context.save()

        return setLog
    }

    /// Delete a set
    func deleteSet(set: SetLog, context: ModelContext) {
        guard let exerciseLog = set.exerciseLog else { return }

        // Remove from exercise log
        exerciseLog.sets.removeAll { $0.id == set.id }

        // Renumber remaining sets
        for (index, remainingSet) in exerciseLog.sortedSets.enumerated() {
            remainingSet.setNumber = index + 1
        }

        context.delete(set)
        try? context.save()
    }

    /// Update an existing set
    func updateSet(
        set: SetLog,
        weight: Double,
        reps: Int,
        rpe: Int?,
        isWarmup: Bool,
        isDropset: Bool,
        context: ModelContext
    ) {
        set.weight = weight
        set.reps = reps
        set.rpe = rpe
        set.isWarmup = isWarmup
        set.isDropset = isDropset

        try? context.save()
    }

    // MARK: - PR Detection

    /// Check if a new set is a personal record
    func checkForPR(
        exercise: Exercise,
        newSet: SetLog,
        user: User,
        context: ModelContext
    ) -> PRInfo? {
        // Don't count warmup sets as PRs
        guard !newSet.isWarmup else { return nil }

        // Get all previous sets for this exercise
        let history = fetchExerciseHistory(exercise: exercise, user: user, context: context)

        // Calculate new estimated 1RM
        let new1RM = newSet.estimated1RM

        // Find best previous 1RM
        let best1RM = history
            .filter { !$0.isWarmup }
            .map { $0.estimated1RM }
            .max() ?? 0

        // Check if this is a PR
        if new1RM > best1RM && best1RM > 0 {
            let improvement = new1RM - best1RM

            let prInfo = PRInfo(
                exerciseName: exercise.name,
                type: .estimated1RM,
                value: new1RM,
                previousValue: best1RM,
                improvement: improvement
            )

            // Post notification
            NotificationCenter.default.post(name: .prAchieved, object: prInfo)

            return prInfo
        }

        return nil
    }

    /// Fetch all historical sets for an exercise
    func fetchExerciseHistory(
        exercise: Exercise,
        user: User,
        context: ModelContext,
        limit: Int = 100
    ) -> [SetLog] {
        var sets: [SetLog] = []

        // Get all completed sessions for this user
        let completedSessions = user.workoutSessions.filter { $0.isCompleted }

        for session in completedSessions {
            for exerciseLog in session.exerciseLogs {
                if exerciseLog.exercise?.id == exercise.id {
                    sets.append(contentsOf: exerciseLog.sets)
                }
            }
        }

        // Sort by date and limit
        sets.sort { $0.timestamp > $1.timestamp }
        return Array(sets.prefix(limit))
    }

    // MARK: - Weight Suggestion

    /// Suggest weight for the next set based on history
    func suggestWeight(
        for exercise: Exercise,
        user: User,
        context: ModelContext
    ) -> Double? {
        let history = fetchExerciseHistory(
            exercise: exercise,
            user: user,
            context: context,
            limit: 20
        )

        // Get most recent working sets
        let recentWorkingSets = history.filter { !$0.isWarmup }.prefix(6)

        guard !recentWorkingSets.isEmpty else { return nil }

        // Use the most common weight from recent sets
        var weightCounts: [Double: Int] = [:]
        for set in recentWorkingSets {
            weightCounts[set.weight, default: 0] += 1
        }

        // Return the most frequently used weight
        return weightCounts.max(by: { $0.value < $1.value })?.key
    }

    /// Suggest reps based on planned exercise
    func suggestReps(for plannedExercise: PlannedExercise) -> Int {
        // Return the middle of the rep range
        return (plannedExercise.targetRepsMin + plannedExercise.targetRepsMax) / 2
    }

    // MARK: - Previous Session

    /// Fetch the most recent completed session for a workout day
    func fetchPreviousSession(
        for workoutDay: WorkoutDay,
        context: ModelContext
    ) -> WorkoutSession? {
        return workoutDay.workoutSessions
            .filter { $0.isCompleted }
            .sorted { $0.startTime > $1.startTime }
            .first
    }

    /// Get previous performance for an exercise
    func getPreviousPerformance(
        exercise: Exercise,
        workoutDay: WorkoutDay,
        context: ModelContext
    ) -> (weight: Double, reps: Int)? {
        guard let previousSession = fetchPreviousSession(for: workoutDay, context: context),
              let exerciseLog = previousSession.exerciseLogs.first(where: { $0.exercise?.id == exercise.id }),
              let bestSet = exerciseLog.bestSet else {
            return nil
        }

        return (bestSet.weight, bestSet.reps)
    }

    /// Get previous sets display string for an exercise
    func getPreviousSetsDisplay(
        exercise: Exercise,
        workoutDay: WorkoutDay,
        context: ModelContext
    ) -> String? {
        guard let previousSession = fetchPreviousSession(for: workoutDay, context: context),
              let exerciseLog = previousSession.exerciseLogs.first(where: { $0.exercise?.id == exercise.id }) else {
            return nil
        }

        let workingSets = exerciseLog.workingSetsArray.prefix(3)
        guard !workingSets.isEmpty else { return nil }

        return workingSets.map { $0.display }.joined(separator: ", ")
    }
}
