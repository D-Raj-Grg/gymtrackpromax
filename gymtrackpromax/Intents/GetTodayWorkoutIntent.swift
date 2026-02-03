//
//  GetTodayWorkoutIntent.swift
//  GymTrack Pro
//
//  Created by Claude Code on 03/02/26.
//

import AppIntents
import Foundation
import SwiftData

/// Intent for querying today's scheduled workout via Siri
/// "What's my workout today?"
struct GetTodayWorkoutIntent: AppIntent {

    // MARK: - Intent Metadata

    static var title: LocalizedStringResource = "What's My Workout Today"
    static var description = IntentDescription("Check what workout is scheduled for today")

    /// This intent can run entirely in the background without opening the app
    static var openAppWhenRun: Bool = false

    // MARK: - Perform

    @MainActor
    func perform() async throws -> some ProvidesDialog {
        let context: ModelContext
        do {
            context = try IntentModelContext.makeContext()
        } catch {
            return .result(dialog: "I couldn't access your workout data. Please open GymTrack Pro to set up.")
        }

        // Check if user exists
        guard let user = try? IntentModelContext.fetchUser(context: context) else {
            return .result(dialog: "You haven't set up GymTrack Pro yet. Please open the app to get started.")
        }

        // Check if user has an active split
        guard let activeSplit = user.activeSplit else {
            return .result(dialog: "You don't have an active workout split. Open GymTrack Pro to create one.")
        }

        // Check if today is a rest day
        guard let todaysWorkout = activeSplit.todaysWorkout else {
            return .result(dialog: "Today is a rest day. Enjoy your recovery!")
        }

        // Build the response
        let exerciseCount = todaysWorkout.exerciseCount
        let duration = todaysWorkout.estimatedDuration
        let muscles = todaysWorkout.primaryMuscles.map { $0.displayName }.joined(separator: " and ")

        let dialog: IntentDialog
        if muscles.isEmpty {
            dialog = IntentDialog(stringLiteral:
                "Today is \(todaysWorkout.name) day with \(exerciseCount) exercises, about \(duration) minutes."
            )
        } else {
            dialog = IntentDialog(stringLiteral:
                "Today is \(todaysWorkout.name) day focusing on \(muscles). You have \(exerciseCount) exercises planned, taking about \(duration) minutes."
            )
        }

        return .result(dialog: dialog)
    }
}
