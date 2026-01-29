//
//  ExerciseLog.swift
//  GymTrack Pro
//
//  Created by Claude Code on 27/01/26.
//

import Foundation
import SwiftData

/// A logged exercise within a workout session
@Model
final class ExerciseLog {
    // MARK: - Properties

    var id: UUID
    var exerciseOrder: Int
    var notes: String?

    // MARK: - Relationships

    var session: WorkoutSession?
    var exercise: Exercise?

    @Relationship(deleteRule: .cascade, inverse: \SetLog.exerciseLog)
    var sets: [SetLog] = []

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        exerciseOrder: Int,
        notes: String? = nil
    ) {
        self.id = id
        self.exerciseOrder = exerciseOrder
        self.notes = notes
    }

    // MARK: - Computed Properties

    /// Sets sorted by set number
    var sortedSets: [SetLog] {
        sets.sorted { $0.setNumber < $1.setNumber }
    }

    /// Working sets (excluding warmup)
    var workingSetsArray: [SetLog] {
        sets.filter { !$0.isWarmup }
    }

    /// Number of working sets
    var workingSets: Int {
        workingSetsArray.count
    }

    /// Warmup sets
    var warmupSets: [SetLog] {
        sets.filter { $0.isWarmup }
    }

    /// Total volume for working sets
    var totalVolume: Double {
        workingSetsArray.reduce(0) { $0 + $1.volume }
    }

    /// Best set by estimated 1RM
    var bestSet: SetLog? {
        workingSetsArray.max { $0.estimated1RM < $1.estimated1RM }
    }

    /// Best weight lifted
    var maxWeight: Double {
        sets.map { $0.weight }.max() ?? 0
    }

    /// Most reps in a set
    var maxReps: Int {
        sets.map { $0.reps }.max() ?? 0
    }

    /// Average RPE across sets
    var averageRPE: Double? {
        let rpes = sets.compactMap { $0.rpe }
        guard !rpes.isEmpty else { return nil }
        return Double(rpes.reduce(0, +)) / Double(rpes.count)
    }

    /// Exercise name (convenience accessor)
    var exerciseName: String {
        exercise?.name ?? "Unknown Exercise"
    }

    /// Display string for sets completed
    var setsDisplay: String {
        "\(workingSets) sets"
    }

    /// Display string for best set
    var bestSetDisplay: String {
        guard let best = bestSet else { return "—" }
        return "\(Int(best.weight)) × \(best.reps)"
    }
}
