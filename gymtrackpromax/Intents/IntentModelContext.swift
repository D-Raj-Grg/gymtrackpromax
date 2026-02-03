//
//  IntentModelContext.swift
//  GymTrack Pro
//
//  Created by Claude Code on 03/02/26.
//

import Foundation
import SwiftData

/// Helper for accessing SwiftData from App Intents
/// Uses the shared App Group container so intents can read/write the same data as the main app
@MainActor
enum IntentModelContext {

    // MARK: - Container Access

    /// Creates a read-write ModelContext for intent operations
    static func makeContext() throws -> ModelContext {
        let container = try SharedModelContainer.makeContainer()
        return ModelContext(container)
    }

    // MARK: - User Queries

    /// Fetches the current user from the database
    static func fetchUser(context: ModelContext) throws -> User? {
        let descriptor = FetchDescriptor<User>()
        return try context.fetch(descriptor).first
    }

    /// Fetches today's scheduled workout for the user
    static func fetchTodaysWorkout(context: ModelContext) throws -> WorkoutDay? {
        guard let user = try fetchUser(context: context) else { return nil }
        return user.activeSplit?.todaysWorkout
    }

    // MARK: - Active Session Queries

    /// Fetches the currently active (in-progress) workout session
    static func fetchActiveSession(context: ModelContext) throws -> WorkoutSession? {
        guard let user = try fetchUser(context: context) else { return nil }

        // Find session that has no endTime (still in progress)
        return user.workoutSessions.first { $0.endTime == nil }
    }

    /// Fetches the current exercise being worked on in an active session
    /// Returns the last exercise log that has at least one set logged
    static func fetchCurrentExercise(session: WorkoutSession) -> ExerciseLog? {
        // Get the most recently logged exercise (by exercise order, with sets)
        return session.sortedExerciseLogs.last { !$0.sets.isEmpty }
            ?? session.sortedExerciseLogs.first
    }

    // MARK: - Workout Day Queries

    /// Fetches a specific workout day by ID
    static func fetchWorkoutDay(id: UUID, context: ModelContext) throws -> WorkoutDay? {
        let descriptor = FetchDescriptor<WorkoutDay>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    /// Fetches all workout days for the active split
    static func fetchAllWorkoutDays(context: ModelContext) throws -> [WorkoutDay] {
        guard let user = try fetchUser(context: context),
              let split = user.activeSplit else {
            return []
        }
        return split.sortedWorkoutDays
    }
}
