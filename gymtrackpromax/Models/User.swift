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

    /// Calculate the current workout streak, skipping rest days based on the active split schedule
    var currentStreak: Int {
        guard !workoutSessions.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get unique completed workout dates
        let workoutDateSet = Set(workoutSessions.compactMap { session -> Date? in
            guard session.endTime != nil else { return nil }
            return calendar.startOfDay(for: session.startTime)
        })

        guard !workoutDateSet.isEmpty else { return 0 }

        // Collect scheduled weekdays from the active split
        let scheduledWeekdays: Set<Int>? = {
            guard let split = activeSplit, split.hasWeekdayScheduling else { return nil }
            var days = Set<Int>()
            for workoutDay in split.workoutDays {
                for weekday in workoutDay.scheduledWeekdays {
                    days.insert(weekday)
                }
            }
            return days.isEmpty ? nil : days
        }()

        // If we have scheduled weekdays, count consecutive scheduled workout days completed
        if let scheduledWeekdays {
            var streak = 0
            var checkDate = today

            // Walk backwards up to 365 days max
            for _ in 0..<365 {
                // weekday: 1=Sunday...7=Saturday in Calendar, convert to 0-indexed (0=Sunday)
                let weekday = calendar.component(.weekday, from: checkDate) - 1

                if scheduledWeekdays.contains(weekday) {
                    // This is a scheduled workout day — must have a workout
                    if workoutDateSet.contains(checkDate) {
                        streak += 1
                    } else {
                        break
                    }
                }
                // Rest day — skip without breaking

                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            }

            return streak
        }

        // Fallback: no active split or no weekday scheduling — use consecutive-day logic with 1-day tolerance
        let workoutDates = workoutDateSet.sorted(by: >)
        var streak = 0
        var currentDate = today

        let firstWorkoutDate = workoutDates[0]
        let daysSinceLastWorkout = calendar.dateComponents([.day], from: firstWorkoutDate, to: today).day ?? 0

        if daysSinceLastWorkout > 1 {
            return 0
        }

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
