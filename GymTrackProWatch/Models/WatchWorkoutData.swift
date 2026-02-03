//
//  WatchWorkoutData.swift
//  GymTrackProWatch
//
//  Local state models for the Watch app.
//

import Foundation

/// Local state for displaying today's workout
enum WatchTodayState {
    case loading
    case restDay(message: String)
    case workout(TodayWorkoutDTO)
    case error(String)
}

/// Local state for an active workout
enum WatchWorkoutState {
    case idle
    case loading
    case active(WorkoutStateDTO)
    case completed(WorkoutCompletedDTO)
    case error(String)
}

/// Input state for set logging
struct WatchSetInput {
    var weight: Double = 0
    var reps: Int = 8
    var isWarmup: Bool = false

    /// Weight increment for Digital Crown
    static let weightIncrement: Double = 0.5

    mutating func reset(suggestedWeight: Double, suggestedReps: Int) {
        weight = suggestedWeight
        reps = suggestedReps
        isWarmup = false
    }
}

/// Focus mode for set input (which field Digital Crown controls)
enum WatchInputFocus {
    case weight
    case reps
}

/// Navigation path for Watch app
enum WatchNavigationDestination: Hashable {
    case activeWorkout
    case summary
}
