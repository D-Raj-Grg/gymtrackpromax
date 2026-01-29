//
//  WorkoutSplit.swift
//  GymTrack Pro
//
//  Created by Claude Code on 27/01/26.
//

import Foundation
import SwiftData

/// A workout split containing multiple workout days
@Model
final class WorkoutSplit {
    // MARK: - Properties

    var id: UUID
    var name: String
    var splitType: SplitType
    var isActive: Bool
    var createdAt: Date

    // MARK: - Relationships

    var user: User?

    @Relationship(deleteRule: .cascade, inverse: \WorkoutDay.split)
    var workoutDays: [WorkoutDay] = []

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        splitType: SplitType,
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.splitType = splitType
        self.isActive = isActive
        self.createdAt = createdAt
    }

    // MARK: - Computed Properties

    /// Number of workout days in this split
    var daysCount: Int {
        workoutDays.count
    }

    /// Workout days sorted by their order
    var sortedWorkoutDays: [WorkoutDay] {
        workoutDays.sorted { $0.dayOrder < $1.dayOrder }
    }

    /// Get the workout scheduled for a specific weekday (0 = Sunday)
    func workoutForWeekday(_ weekday: Int) -> WorkoutDay? {
        workoutDays.first { $0.scheduledWeekdays.contains(weekday) }
    }

    /// Get today's scheduled workout
    /// First tries to find a workout scheduled for today's weekday
    /// Falls back to sequential day based on dayOrder if no weekdays are scheduled
    var todaysWorkout: WorkoutDay? {
        let weekday = Calendar.current.component(.weekday, from: Date()) - 1 // Convert to 0-indexed (0=Sunday)

        // First, try to find workout scheduled for today's weekday
        if let scheduledWorkout = workoutForWeekday(weekday) {
            return scheduledWorkout
        }

        // Check if any workout days have weekday assignments
        let hasScheduledDays = workoutDays.contains { !$0.scheduledWeekdays.isEmpty }

        // If no days have weekday assignments, use sequential fallback
        if !hasScheduledDays && !workoutDays.isEmpty {
            // Use weekday to determine which day in sequence
            // Monday (weekday 1) = Day 0, Tuesday = Day 1, etc.
            // Sunday is rest day in sequential mode
            if weekday == 0 {
                return nil // Sunday is rest day
            }
            let dayIndex = (weekday - 1) % workoutDays.count
            return sortedWorkoutDays[dayIndex]
        }

        return nil
    }

    /// Whether today is a rest day
    var isRestDay: Bool {
        todaysWorkout == nil
    }

    /// Check if this split has weekday scheduling configured
    var hasWeekdayScheduling: Bool {
        workoutDays.contains { !$0.scheduledWeekdays.isEmpty }
    }

    /// All muscle groups trained in this split
    var allMuscleGroups: Set<MuscleGroup> {
        var muscles = Set<MuscleGroup>()
        for day in workoutDays {
            muscles.formUnion(day.targetMuscles)
        }
        return muscles
    }
}
