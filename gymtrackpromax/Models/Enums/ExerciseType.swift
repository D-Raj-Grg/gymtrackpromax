//
//  ExerciseType.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import Foundation

/// Types of exercises based on how they are measured
enum ExerciseType: String, Codable, CaseIterable {
    /// Standard weighted exercise (e.g., Bench Press, Squat)
    case weightAndReps = "weightAndReps"

    /// Bodyweight exercise with reps only (e.g., Push-ups, Pull-ups)
    case repsOnly = "repsOnly"

    /// Timed/duration exercise (e.g., Plank, Wall Sit, Dead Hang)
    case duration = "duration"

    /// Weighted exercise measured by duration (e.g., Farmer's Walk, Weighted Plank)
    case weightAndDuration = "weightAndDuration"

    // MARK: - Display Properties

    /// Display name for UI
    var displayName: String {
        switch self {
        case .weightAndReps:
            return "Weight × Reps"
        case .repsOnly:
            return "Reps Only"
        case .duration:
            return "Duration"
        case .weightAndDuration:
            return "Weight × Duration"
        }
    }

    // MARK: - Input Configuration

    /// Whether this exercise type shows weight input by default
    var showsWeight: Bool {
        self == .weightAndReps || self == .weightAndDuration
    }

    /// Whether this exercise type shows reps input
    var showsReps: Bool {
        self == .weightAndReps || self == .repsOnly
    }

    /// Whether this exercise type shows duration input
    var showsDuration: Bool {
        self == .duration || self == .weightAndDuration
    }

    /// Whether this exercise type allows optional weight (for bodyweight + weight variations)
    var allowsOptionalWeight: Bool {
        self == .repsOnly
    }
}
