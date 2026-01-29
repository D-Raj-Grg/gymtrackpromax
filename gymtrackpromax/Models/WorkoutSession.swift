//
//  WorkoutSession.swift
//  GymTrack Pro
//
//  Created by Claude Code on 27/01/26.
//

import Foundation
import SwiftData

/// A logged workout session
@Model
final class WorkoutSession {
    // MARK: - Properties

    var id: UUID
    var startTime: Date
    var endTime: Date?
    var notes: String?

    // MARK: - Relationships

    var user: User?
    var workoutDay: WorkoutDay?

    @Relationship(deleteRule: .cascade, inverse: \ExerciseLog.session)
    var exerciseLogs: [ExerciseLog] = []

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.notes = notes
    }

    // MARK: - Computed Properties

    /// Whether the workout is currently in progress
    var isInProgress: Bool {
        endTime == nil
    }

    /// Whether the workout is completed
    var isCompleted: Bool {
        endTime != nil
    }

    /// Duration of the workout in seconds
    var duration: TimeInterval? {
        guard let end = endTime else { return nil }
        return end.timeIntervalSince(startTime)
    }

    /// Duration display string (e.g., "1h 23m")
    var durationDisplay: String {
        guard let seconds = duration else { return "In Progress" }

        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    /// Total volume (weight × reps) for working sets
    var totalVolume: Double {
        exerciseLogs.reduce(0) { $0 + $1.totalVolume }
    }

    /// Total volume display string
    var totalVolumeDisplay: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: totalVolume)) ?? "0"
    }

    /// Total number of sets completed
    var totalSets: Int {
        exerciseLogs.reduce(0) { $0 + $1.sets.count }
    }

    /// Total number of working sets (excluding warmup)
    var workingSets: Int {
        exerciseLogs.reduce(0) { $0 + $1.workingSets }
    }

    /// Number of exercises completed
    var exercisesCompleted: Int {
        exerciseLogs.count
    }

    /// Exercise logs sorted by order
    var sortedExerciseLogs: [ExerciseLog] {
        exerciseLogs.sorted { $0.exerciseOrder < $1.exerciseOrder }
    }

    /// Workout name from the workout day
    var workoutName: String {
        workoutDay?.name ?? "Quick Workout"
    }

    /// Target muscles from completed exercises
    var targetMuscles: Set<MuscleGroup> {
        var muscles = Set<MuscleGroup>()
        for log in exerciseLogs {
            if let exercise = log.exercise {
                muscles.insert(exercise.primaryMuscle)
            }
        }
        return muscles
    }

    /// Display string for target muscles
    var musclesDisplay: String {
        targetMuscles.map { $0.displayName }.sorted().joined(separator: ", ")
    }
}
