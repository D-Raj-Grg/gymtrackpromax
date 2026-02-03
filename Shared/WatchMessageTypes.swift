//
//  WatchMessageTypes.swift
//  GymTrack Pro
//
//  Shared between iPhone and Watch for WatchConnectivity communication.
//

import Foundation

/// Message types for Watch-iPhone communication
enum WatchMessageType: String, Codable {
    // MARK: - Watch → iPhone Requests

    /// Watch requests today's workout info
    case requestTodayWorkout

    /// Watch requests to start a workout
    case startWorkout

    /// Watch logs a set
    case logSet

    /// Watch requests current workout state
    case requestWorkoutState

    /// Watch requests to complete the workout
    case completeWorkout

    /// Watch requests to skip to next exercise
    case nextExercise

    /// Watch requests to go to previous exercise
    case previousExercise

    // MARK: - iPhone → Watch Responses

    /// iPhone sends today's workout info
    case todayWorkout

    /// iPhone sends rest day info
    case restDay

    /// iPhone sends current workout state
    case workoutState

    /// iPhone confirms set was logged
    case setLogConfirmation

    /// iPhone notifies workout completed
    case workoutCompleted

    /// iPhone sends error message
    case error
}

/// Message keys for WatchConnectivity dictionaries
enum WatchMessageKey: String {
    case messageType = "type"
    case payload = "payload"
    case errorMessage = "error"
    case workoutDayId = "workoutDayId"
    case exerciseLogId = "exerciseLogId"
}

/// Error types for Watch communication
enum WatchConnectivityError: String, Error, Codable {
    case noActiveUser = "No active user found"
    case noActiveSplit = "No active workout split"
    case noWorkoutToday = "No workout scheduled for today"
    case noActiveSession = "No active workout session"
    case workoutAlreadyInProgress = "Workout already in progress"
    case invalidPayload = "Invalid message payload"
    case exerciseNotFound = "Exercise not found"
    case encodingFailed = "Failed to encode data"
    case decodingFailed = "Failed to decode data"
    case sessionNotReachable = "Watch/Phone not reachable"

    var localizedDescription: String {
        self.rawValue
    }
}
