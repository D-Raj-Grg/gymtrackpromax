//
//  User.swift
//  GymTrack Pro
//
//  Created by Claude Code on 27/01/26.
//

import Foundation
import SwiftData

/// User profile containing personal information and preferences
@Model
final class User {
    // MARK: - Properties

    var id: UUID
    var name: String
    var profileImageData: Data?
    var weightUnit: WeightUnit
    var weekStartDay: WeekStartDay = WeekStartDay.monday
    var experienceLevel: ExperienceLevel
    var fitnessGoal: FitnessGoal
    var createdAt: Date

    // MARK: - Relationships

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSplit.user)
    var workoutSplits: [WorkoutSplit] = []

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSession.user)
    var workoutSessions: [WorkoutSession] = []

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        weightUnit: WeightUnit = .kg,
        weekStartDay: WeekStartDay = .systemDefault,
        experienceLevel: ExperienceLevel = .beginner,
        fitnessGoal: FitnessGoal = .buildMuscle,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.weightUnit = weightUnit
        self.weekStartDay = weekStartDay
        self.experienceLevel = experienceLevel
        self.fitnessGoal = fitnessGoal
        self.createdAt = createdAt
    }

    // MARK: - Computed Properties

    /// The currently active workout split
    var activeSplit: WorkoutSplit? {
        workoutSplits.first { $0.isActive }
    }

    /// Total number of completed workouts
    var totalWorkouts: Int {
        workoutSessions.filter { $0.endTime != nil }.count
    }

    /// Calculate the current workout streak
    var currentStreak: Int {
        guard !workoutSessions.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get unique workout dates (sorted descending)
        let workoutDates = Set(workoutSessions.compactMap { session -> Date? in
            guard session.endTime != nil else { return nil }
            return calendar.startOfDay(for: session.startTime)
        }).sorted(by: >)

        guard !workoutDates.isEmpty else { return 0 }

        var streak = 0
        var currentDate = today

        // Check if worked out today or yesterday
        let firstWorkoutDate = workoutDates[0]
        let daysSinceLastWorkout = calendar.dateComponents([.day], from: firstWorkoutDate, to: today).day ?? 0

        if daysSinceLastWorkout > 1 {
            return 0 // Streak broken
        }

        // Start counting from the most recent workout
        currentDate = firstWorkoutDate

        for workoutDate in workoutDates {
            let daysDiff = calendar.dateComponents([.day], from: workoutDate, to: currentDate).day ?? 0

            if daysDiff <= 1 {
                streak += 1
                currentDate = workoutDate
            } else {
                break
            }
        }

        return streak
    }
}
