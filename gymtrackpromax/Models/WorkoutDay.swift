//
//  WorkoutDay.swift
//  GymTrack Pro
//
//  Created by Claude Code on 27/01/26.
//

import Foundation
import SwiftData

/// A single workout day within a split
@Model
final class WorkoutDay {
    // MARK: - Properties

    var id: UUID
    var name: String
    var dayOrder: Int
    var scheduledWeekdays: [Int] // 0 = Sunday, 1 = Monday, etc.

    // MARK: - Relationships

    var split: WorkoutSplit?

    @Relationship(deleteRule: .cascade, inverse: \PlannedExercise.workoutDay)
    var plannedExercises: [PlannedExercise] = []

    @Relationship(inverse: \WorkoutSession.workoutDay)
    var workoutSessions: [WorkoutSession] = []

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        dayOrder: Int,
        scheduledWeekdays: [Int] = []
    ) {
        self.id = id
        self.name = name
        self.dayOrder = dayOrder
        self.scheduledWeekdays = scheduledWeekdays
    }

    // MARK: - Computed Properties

    /// Exercises sorted by their order
    var sortedExercises: [PlannedExercise] {
        plannedExercises.sorted { $0.exerciseOrder < $1.exerciseOrder }
    }

    /// Exercises grouped by superset (standalone exercises become single-item groups)
    var exerciseGroups: [[PlannedExercise]] {
        var groups: [[PlannedExercise]] = []
        var usedIds = Set<UUID>()

        for exercise in sortedExercises {
            guard !usedIds.contains(exercise.id) else { continue }

            if let groupId = exercise.supersetGroupId {
                // Collect all exercises in this superset group
                let group = sortedExercises
                    .filter { $0.supersetGroupId == groupId }
                    .sorted { $0.supersetOrder < $1.supersetOrder }
                for e in group { usedIds.insert(e.id) }
                groups.append(group)
            } else {
                usedIds.insert(exercise.id)
                groups.append([exercise])
            }
        }

        return groups
    }

    /// Number of exercises in this workout
    var exerciseCount: Int {
        plannedExercises.count
    }

    /// Total sets planned for this workout
    var totalSets: Int {
        plannedExercises.reduce(0) { $0 + $1.targetSets }
    }

    /// Estimated workout duration in minutes
    var estimatedDuration: Int {
        // Rough estimate: 3 minutes per set (including rest)
        totalSets * 3
    }

    /// Target muscle groups for this workout day
    var targetMuscles: Set<MuscleGroup> {
        var muscles = Set<MuscleGroup>()
        for planned in plannedExercises {
            if let exercise = planned.exercise {
                muscles.insert(exercise.primaryMuscle)
                muscles.formUnion(exercise.secondaryMuscles)
            }
        }
        return muscles
    }

    /// Primary muscle groups (most trained)
    var primaryMuscles: [MuscleGroup] {
        var muscleCount: [MuscleGroup: Int] = [:]
        for planned in plannedExercises {
            if let exercise = planned.exercise {
                muscleCount[exercise.primaryMuscle, default: 0] += planned.targetSets
            }
        }
        return muscleCount.sorted { $0.value > $1.value }.prefix(3).map { $0.key }
    }

    /// Display string for scheduled weekdays
    var scheduledDaysDisplay: String {
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let sortedDays = scheduledWeekdays.sorted()
        return sortedDays.map { dayNames[$0] }.joined(separator: ", ")
    }

    /// Most recent completed session for this workout
    var lastSession: WorkoutSession? {
        workoutSessions
            .filter { $0.endTime != nil }
            .sorted { $0.startTime > $1.startTime }
            .first
    }

    /// In-progress session (saved but not completed, with at least one logged set)
    var inProgressSession: WorkoutSession? {
        workoutSessions.first { $0.endTime == nil && !$0.exerciseLogs.isEmpty }
    }
}
