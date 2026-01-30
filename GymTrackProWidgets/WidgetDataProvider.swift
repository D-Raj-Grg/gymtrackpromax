//
//  WidgetDataProvider.swift
//  GymTrackProWidgets
//
//  Created by Claude Code on 30/01/26.
//

import Foundation
import SwiftData

/// Centralized data fetching for all widgets.
/// Uses a read-only ModelContainer via SharedModelContainer.
struct WidgetDataProvider {

    // MARK: - Widget Data

    /// All data a widget might need, fetched in one pass.
    struct WidgetData {
        let streakCount: Int
        let todayWorkoutName: String?
        let todayMuscleGroups: [String]
        let todayExerciseCount: Int
        let todayEstimatedDuration: Int
        let isRestDay: Bool
        let weeklyWorkoutCount: Int
        let weeklyVolume: Double
        let weeklyPRCount: Int
        let weightUnitSymbol: String

        static let empty = WidgetData(
            streakCount: 0,
            todayWorkoutName: nil,
            todayMuscleGroups: [],
            todayExerciseCount: 0,
            todayEstimatedDuration: 0,
            isRestDay: true,
            weeklyWorkoutCount: 0,
            weeklyVolume: 0,
            weeklyPRCount: 0,
            weightUnitSymbol: "kg"
        )

        static let preview = WidgetData(
            streakCount: 7,
            todayWorkoutName: "Push Day",
            todayMuscleGroups: ["Chest", "Shoulders", "Triceps"],
            todayExerciseCount: 6,
            todayEstimatedDuration: 55,
            isRestDay: false,
            weeklyWorkoutCount: 4,
            weeklyVolume: 12500,
            weeklyPRCount: 2,
            weightUnitSymbol: "kg"
        )
    }

    // MARK: - Fetch

    /// Fetches all widget-relevant data from the shared store.
    static func fetchData() -> WidgetData {
        guard let container = try? SharedModelContainer.makeReadOnlyContainer() else {
            return .empty
        }

        let context = ModelContext(container)

        // Fetch user
        let userDescriptor = FetchDescriptor<User>()
        guard let user = try? context.fetch(userDescriptor).first else {
            return .empty
        }

        let weightUnitSymbol = user.weightUnit.symbol

        // Streak
        let streakCount = user.currentStreak

        // Today's workout
        let activeSplit = user.activeSplit
        let todaysWorkout = activeSplit?.todaysWorkout
        let isRestDay = activeSplit?.isRestDay ?? true
        let todayWorkoutName = todaysWorkout?.name
        let todayMuscleGroups = todaysWorkout?.primaryMuscles.map { $0.displayName } ?? []
        let todayExerciseCount = todaysWorkout?.exerciseCount ?? 0
        let todayEstimatedDuration = todaysWorkout?.estimatedDuration ?? 0

        // Weekly stats
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now

        var weeklySessionDescriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.startTime >= startOfWeek && session.endTime != nil
            }
        )
        weeklySessionDescriptor.fetchLimit = 50

        let weeklySessions = (try? context.fetch(weeklySessionDescriptor)) ?? []
        let weeklyWorkoutCount = weeklySessions.count
        let weeklyVolume = weeklySessions.reduce(0.0) { $0 + $1.totalVolume }

        // Weekly PRs — count sessions that have any PR-worthy sets
        // For simplicity, count the number of unique exercises with new best 1RMs this week
        let weeklyPRCount = countWeeklyPRs(sessions: weeklySessions, user: user, context: context)

        return WidgetData(
            streakCount: streakCount,
            todayWorkoutName: todayWorkoutName,
            todayMuscleGroups: todayMuscleGroups,
            todayExerciseCount: todayExerciseCount,
            todayEstimatedDuration: todayEstimatedDuration,
            isRestDay: isRestDay,
            weeklyWorkoutCount: weeklyWorkoutCount,
            weeklyVolume: weeklyVolume,
            weeklyPRCount: weeklyPRCount,
            weightUnitSymbol: weightUnitSymbol
        )
    }

    // MARK: - PR Counting

    /// Counts how many exercises achieved a PR this week by comparing best 1RM in weekly sessions
    /// to best 1RM in all prior sessions.
    private static func countWeeklyPRs(sessions: [WorkoutSession], user: User, context: ModelContext) -> Int {
        var prCount = 0

        // Gather all exercise logs from this week's sessions
        var weeklyBestByExercise: [UUID: Double] = [:]
        for session in sessions {
            for log in (session.exerciseLogs ?? []) {
                guard let exerciseID = log.exercise?.id else { continue }
                let best1RM = log.bestSet?.estimated1RM ?? 0
                if best1RM > (weeklyBestByExercise[exerciseID] ?? 0) {
                    weeklyBestByExercise[exerciseID] = best1RM
                }
            }
        }

        // Compare against all-time bests (excluding this week)
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()

        for (exerciseID, weeklyBest) in weeklyBestByExercise {
            var descriptor = FetchDescriptor<WorkoutSession>(
                predicate: #Predicate<WorkoutSession> { session in
                    session.startTime < startOfWeek && session.endTime != nil
                }
            )
            descriptor.fetchLimit = 200

            let priorSessions = (try? context.fetch(descriptor)) ?? []
            var priorBest: Double = 0
            for session in priorSessions {
                for log in (session.exerciseLogs ?? []) {
                    guard log.exercise?.id == exerciseID else { continue }
                    let best1RM = log.bestSet?.estimated1RM ?? 0
                    if best1RM > priorBest {
                        priorBest = best1RM
                    }
                }
            }

            if weeklyBest > priorBest && priorBest > 0 {
                prCount += 1
            }
        }

        return prCount
    }
}
