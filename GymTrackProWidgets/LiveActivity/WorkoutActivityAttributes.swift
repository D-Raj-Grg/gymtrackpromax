//
//  WorkoutActivityAttributes.swift
//  GymTrack Pro
//
//  Created by Claude Code on 30/01/26.
//

import ActivityKit
import Foundation

struct WorkoutActivityAttributes: ActivityAttributes {
    // MARK: - Static Data (set once at start)

    var workoutName: String
    var startTime: Date
    var totalExercises: Int

    // MARK: - Dynamic Content State

    struct ContentState: Codable, Hashable {
        var currentExerciseName: String
        var currentMuscleGroup: String
        var setsCompleted: Int
        var targetSets: Int
        var currentExerciseNumber: Int
        var totalSetsLogged: Int
        var isResting: Bool
        var restTimerStart: Date?
        var restTimerEnd: Date?
    }
}
