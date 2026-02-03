//
//  WorkoutDayEntity.swift
//  GymTrack Pro
//
//  Created by Claude Code on 03/02/26.
//

import AppIntents
import Foundation

/// AppEntity wrapper for WorkoutDay to enable Siri parameter suggestions
struct WorkoutDayEntity: AppEntity {

    // MARK: - Properties

    var id: UUID
    var name: String
    var exerciseCount: Int
    var estimatedDuration: Int
    var muscleGroups: String

    // MARK: - AppEntity Requirements

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Workout")
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(exerciseCount) exercises • ~\(estimatedDuration) min"
        )
    }

    static var defaultQuery = WorkoutDayQuery()

    // MARK: - Initialization

    init(id: UUID, name: String, exerciseCount: Int, estimatedDuration: Int, muscleGroups: String) {
        self.id = id
        self.name = name
        self.exerciseCount = exerciseCount
        self.estimatedDuration = estimatedDuration
        self.muscleGroups = muscleGroups
    }

    /// Creates an entity from a WorkoutDay model
    @MainActor
    init(from workoutDay: WorkoutDay) {
        self.id = workoutDay.id
        self.name = workoutDay.name
        self.exerciseCount = workoutDay.exerciseCount
        self.estimatedDuration = workoutDay.estimatedDuration
        self.muscleGroups = workoutDay.primaryMuscles.map { $0.displayName }.joined(separator: ", ")
    }
}

// MARK: - Entity Query

struct WorkoutDayQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [WorkoutDayEntity] {
        let context = try IntentModelContext.makeContext()
        let allDays = try IntentModelContext.fetchAllWorkoutDays(context: context)

        return allDays
            .filter { identifiers.contains($0.id) }
            .map { WorkoutDayEntity(from: $0) }
    }

    @MainActor
    func suggestedEntities() async throws -> [WorkoutDayEntity] {
        let context = try IntentModelContext.makeContext()
        let allDays = try IntentModelContext.fetchAllWorkoutDays(context: context)

        return allDays.map { WorkoutDayEntity(from: $0) }
    }
}

// MARK: - String Search Support

extension WorkoutDayQuery: EntityStringQuery {
    @MainActor
    func entities(matching string: String) async throws -> [WorkoutDayEntity] {
        let context = try IntentModelContext.makeContext()
        let allDays = try IntentModelContext.fetchAllWorkoutDays(context: context)

        let lowercasedQuery = string.lowercased()

        return allDays
            .filter { $0.name.lowercased().contains(lowercasedQuery) }
            .map { WorkoutDayEntity(from: $0) }
    }
}
