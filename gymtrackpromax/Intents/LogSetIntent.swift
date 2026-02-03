//
//  LogSetIntent.swift
//  GymTrack Pro
//
//  Created by Claude Code on 03/02/26.
//

import AppIntents
import Foundation
import SwiftData

/// Intent for logging a set via Siri during an active workout
/// "Log a set at 100 kilos for 8 reps"
struct LogSetIntent: AppIntent {

    // MARK: - Intent Metadata

    static var title: LocalizedStringResource = "Log a Set"
    static var description = IntentDescription("Log weight and reps to your current exercise")

    /// This intent can run in the background without opening the app
    static var openAppWhenRun: Bool = false

    // MARK: - Parameters

    @Parameter(title: "Weight", description: "Weight in kilograms")
    var weight: Double

    @Parameter(title: "Reps", description: "Number of repetitions")
    var reps: Int

    // MARK: - Perform

    @MainActor
    func perform() async throws -> some ProvidesDialog {
        let context: ModelContext
        do {
            context = try IntentModelContext.makeContext()
        } catch {
            return .result(dialog: "I couldn't access your workout data. Please try again.")
        }

        // Check for active workout session
        guard let activeSession = try? IntentModelContext.fetchActiveSession(context: context) else {
            return .result(dialog: "You don't have an active workout. Start a workout first, then try logging sets.")
        }

        // Find the current exercise being worked on
        guard let currentExercise = IntentModelContext.fetchCurrentExercise(session: activeSession) else {
            return .result(dialog: "No exercises found in your current workout. Please add an exercise first.")
        }

        // Validate inputs
        guard weight > 0 else {
            return .result(dialog: "Please specify a valid weight.")
        }

        guard reps > 0 else {
            return .result(dialog: "Please specify a valid number of reps.")
        }

        // Determine the next set number
        let nextSetNumber = currentExercise.sets.count + 1

        // Create and save the new set
        let newSet = SetLog(
            setNumber: nextSetNumber,
            weight: weight,
            reps: reps,
            isWarmup: false,
            isDropset: false,
            timestamp: Date()
        )

        newSet.exerciseLog = currentExercise
        context.insert(newSet)

        do {
            try context.save()
        } catch {
            return .result(dialog: "I couldn't save the set. Please try again.")
        }

        // Post notification to update UI if app is visible
        NotificationCenter.default.post(
            name: .setLoggedFromIntent,
            object: nil,
            userInfo: [
                "exerciseLogId": currentExercise.id.uuidString,
                "setId": newSet.id.uuidString
            ]
        )

        // Build confirmation response
        let exerciseName = currentExercise.exerciseName
        let weightDisplay = weight.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(weight))"
            : String(format: "%.1f", weight)

        return .result(dialog: "Logged \(weightDisplay) kilos for \(reps) reps on \(exerciseName). Set \(nextSetNumber) complete.")
    }
}

// MARK: - Parameter Summary

extension LogSetIntent {
    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$weight) kg for \(\.$reps) reps")
    }
}
