//
//  StartWorkoutIntent.swift
//  GymTrack Pro
//
//  Created by Claude Code on 03/02/26.
//

import AppIntents
import Foundation
import SwiftData

/// Intent for starting a workout via Siri
/// "Start my workout" or "Start my push day"
struct StartWorkoutIntent: AppIntent {

    // MARK: - Intent Metadata

    static var title: LocalizedStringResource = "Start Workout"
    static var description = IntentDescription("Start your scheduled workout or a specific workout day")

    /// This intent must open the app to show the workout UI
    static var openAppWhenRun: Bool = true

    // MARK: - Parameters

    @Parameter(title: "Workout", description: "Which workout to start (optional, defaults to today's workout)")
    var workout: WorkoutDayEntity?

    // MARK: - Perform

    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        let context: ModelContext
        do {
            context = try IntentModelContext.makeContext()
        } catch {
            throw IntentError.message("I couldn't access your workout data. Please try again.")
        }

        // Check if user exists
        guard let user = try? IntentModelContext.fetchUser(context: context) else {
            throw IntentError.message("Please open GymTrack Pro to set up your profile first.")
        }

        // Check if user has an active split
        guard let activeSplit = user.activeSplit else {
            throw IntentError.message("You need to create a workout split first. Open GymTrack Pro to get started.")
        }

        // Determine which workout to start
        let workoutDay: WorkoutDay

        if let selectedWorkout = workout {
            // User specified a workout
            guard let day = try? IntentModelContext.fetchWorkoutDay(id: selectedWorkout.id, context: context) else {
                throw IntentError.message("I couldn't find that workout. Please try again.")
            }
            workoutDay = day
        } else {
            // Use today's scheduled workout
            guard let todaysWorkout = activeSplit.todaysWorkout else {
                throw IntentError.message("Today is a rest day. Enjoy your recovery, or specify which workout you want to start.")
            }
            workoutDay = todaysWorkout
        }

        // Post notification to navigate to workout
        NotificationCenter.default.post(
            name: .startWorkoutFromIntent,
            object: nil,
            userInfo: ["workoutDayId": workoutDay.id.uuidString]
        )

        return .result()
    }
}

// MARK: - Intent Error

/// Custom error type for App Intents that speaks the error message to the user
enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case message(String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .message(let text):
            return LocalizedStringResource(stringLiteral: text)
        }
    }
}
