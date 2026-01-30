//
//  WidgetDataProvider.swift
//  GymTrackProWidgets
//
//  Created by Claude Code on 30/01/26.
//

import Foundation
import SwiftData
import os

/// Centralized data fetching for all widgets.
/// Uses a read-only ModelContainer via SharedModelContainer.
struct WidgetDataProvider {

    private static let logger = Logger(subsystem: "gymtrackpromax.widgets", category: "DataProvider")

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
        let container: ModelContainer
        do {
            container = try SharedModelContainer.makeReadOnlyContainer()
        } catch {
            logger.error("Failed to create read-only ModelContainer: \(error.localizedDescription)")
            logger.error("Store URL: \(SharedModelContainer.sharedStoreURL.path)")
            let diagnostics = SharedModelContainer.diagnoseAppGroup()
            logger.error("Diagnostics — containerAccessible: \(diagnostics.containerAccessible), dbExists: \(diagnostics.databaseExists)")
            return .empty
        }

        let context = ModelContext(container)

        // Fetch user
        let userDescriptor = FetchDescriptor<User>()
        let user: User
        do {
            guard let fetchedUser = try context.fetch(userDescriptor).first else {
                logger.warning("No User found in shared store — onboarding may not be complete")
                return .empty
            }
            user = fetchedUser
        } catch {
            logger.error("Failed to fetch User: \(error.localizedDescription)")
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

    /// Counts PRs achieved this week using the same logic as the app's ProgressViewModel:
    /// Process all sessions chronologically, counting every set that beats the exercise's
    /// all-time best estimated 1RM. First-time exercises count as PRs.
    private static func countWeeklyPRs(sessions weeklySessions: [WorkoutSession], user: User, context: ModelContext) -> Int {
        // Fetch all completed sessions to build chronological PR history
        var allSessionsDescriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.endTime != nil
            }
        )
        allSessionsDescriptor.fetchLimit = 500

        let allSessions = (try? context.fetch(allSessionsDescriptor)) ?? []
        let sortedSessions = allSessions.filter { $0.endTime != nil }.sorted { $0.startTime < $1.startTime }

        // Build set of weekly session IDs for filtering
        let weeklySessionIds = Set(weeklySessions.map { $0.id })

        // Track best 1RM per exercise chronologically
        var exerciseBests: [UUID: Double] = [:]
        var prsInWeek = 0

        for session in sortedSessions {
            for log in (session.exerciseLogs ?? []) {
                guard let exercise = log.exercise else { continue }

                // Check each working set (non-warmup)
                for set in (log.sets ?? []) {
                    guard !set.isWarmup else { continue }

                    let estimated1RM = set.estimated1RM
                    let currentBest = exerciseBests[exercise.id] ?? 0

                    if estimated1RM > currentBest {
                        exerciseBests[exercise.id] = estimated1RM

                        // Count as PR if this session is in the current week
                        if weeklySessionIds.contains(session.id) {
                            prsInWeek += 1
                        }
                    }
                }
            }
        }

        return prsInWeek
    }
}
