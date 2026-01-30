//
//  LiveActivityService.swift
//  GymTrack Pro
//
//  Created by Claude Code on 30/01/26.
//

import ActivityKit
import Foundation

@MainActor
final class LiveActivityService {
    static let shared = LiveActivityService()

    private var currentActivity: Activity<WorkoutActivityAttributes>?

    private init() {}

    // MARK: - Start

    func startActivity(
        workoutName: String,
        startTime: Date,
        totalExercises: Int,
        initialState: WorkoutActivityAttributes.ContentState
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = WorkoutActivityAttributes(
            workoutName: workoutName,
            startTime: startTime,
            totalExercises: totalExercises
        )

        let content = ActivityContent(state: initialState, staleDate: nil)

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    // MARK: - Update

    func updateActivity(state: WorkoutActivityAttributes.ContentState) {
        guard let activity = currentActivity else { return }
        let content = ActivityContent(state: state, staleDate: nil)

        Task {
            await activity.update(content)
        }
    }

    // MARK: - Rest Timer

    func startRestTimer(
        currentState: WorkoutActivityAttributes.ContentState,
        restDuration: TimeInterval
    ) {
        var state = currentState
        let now = Date()
        state.isResting = true
        state.restTimerStart = now
        state.restTimerEnd = now.addingTimeInterval(restDuration)
        updateActivity(state: state)
    }

    func clearRestTimer(
        currentState: WorkoutActivityAttributes.ContentState
    ) {
        var state = currentState
        state.isResting = false
        state.restTimerStart = nil
        state.restTimerEnd = nil
        updateActivity(state: state)
    }

    // MARK: - End

    func endActivity() {
        guard let activity = currentActivity else { return }

        let finalState = activity.content.state
        let content = ActivityContent(state: finalState, staleDate: nil)

        Task {
            await activity.end(content, dismissalPolicy: .default)
        }

        currentActivity = nil
    }
}
