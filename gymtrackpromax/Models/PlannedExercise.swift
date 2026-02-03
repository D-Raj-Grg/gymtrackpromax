//
//  PlannedExercise.swift
//  GymTrack Pro
//
//  Created by Claude Code on 27/01/26.
//

import Foundation
import SwiftData

/// An exercise planned for a workout day
@Model
final class PlannedExercise {
    // MARK: - Properties

    var id: UUID
    var exerciseOrder: Int
    var targetSets: Int
    var targetRepsMin: Int
    var targetRepsMax: Int
    var restSeconds: Int
    var notes: String?
    var supersetGroupId: UUID? = nil
    var supersetOrder: Int = 0

    // MARK: - Relationships

    var workoutDay: WorkoutDay?
    var exercise: Exercise?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        exerciseOrder: Int,
        targetSets: Int = 3,
        targetRepsMin: Int = 8,
        targetRepsMax: Int = 12,
        restSeconds: Int = 90,
        notes: String? = nil,
        supersetGroupId: UUID? = nil,
        supersetOrder: Int = 0
    ) {
        self.id = id
        self.exerciseOrder = exerciseOrder
        self.targetSets = targetSets
        self.targetRepsMin = targetRepsMin
        self.targetRepsMax = targetRepsMax
        self.restSeconds = restSeconds
        self.notes = notes
        self.supersetGroupId = supersetGroupId
        self.supersetOrder = supersetOrder
    }

    // MARK: - Computed Properties

    /// Whether this exercise is part of a superset
    var isInSuperset: Bool {
        supersetGroupId != nil
    }

    /// Display string for target reps
    var targetRepsDisplay: String {
        if targetRepsMin == targetRepsMax {
            return "\(targetRepsMin) reps"
        }
        return "\(targetRepsMin)-\(targetRepsMax) reps"
    }

    /// Display string for sets and reps
    var setsAndRepsDisplay: String {
        "\(targetSets) × \(targetRepsDisplay)"
    }

    /// Rest time display string
    var restDisplay: String {
        if restSeconds >= 60 {
            let minutes = restSeconds / 60
            let seconds = restSeconds % 60
            if seconds == 0 {
                return "\(minutes)m rest"
            }
            return "\(minutes)m \(seconds)s rest"
        }
        return "\(restSeconds)s rest"
    }

    /// Exercise name (convenience accessor)
    var exerciseName: String {
        exercise?.name ?? "Unknown Exercise"
    }

    /// Primary muscle group (convenience accessor)
    var primaryMuscle: MuscleGroup? {
        exercise?.primaryMuscle
    }
}
