//
//  SetLog.swift
//  GymTrack Pro
//
//  Created by Claude Code on 27/01/26.
//

import Foundation
import SwiftData

/// A single set logged during a workout
@Model
final class SetLog {
    // MARK: - Properties

    var id: UUID
    var setNumber: Int
    var weight: Double
    var reps: Int
    var duration: Int? // Duration in seconds (for timed exercises)
    var rpe: Int? // Rate of Perceived Exertion (1-10)
    var isWarmup: Bool
    var isDropset: Bool
    var timestamp: Date

    // MARK: - Relationships

    var exerciseLog: ExerciseLog?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        setNumber: Int,
        weight: Double = 0,
        reps: Int = 0,
        duration: Int? = nil,
        rpe: Int? = nil,
        isWarmup: Bool = false,
        isDropset: Bool = false,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.duration = duration
        self.rpe = rpe
        self.isWarmup = isWarmup
        self.isDropset = isDropset
        self.timestamp = timestamp
    }

    // MARK: - Computed Properties

    /// Volume for this set (weight × reps)
    var volume: Double {
        weight * Double(reps)
    }

    /// Estimated 1 Rep Max using Epley formula
    var estimated1RM: Double {
        guard reps > 0 else { return 0 }
        if reps == 1 {
            return weight
        }
        return weight * (1 + Double(reps) / 30)
    }

    /// Whether this is a duration-based set
    var isDurationSet: Bool {
        duration != nil
    }

    /// Display string for weight and reps (or duration)
    var display: String {
        if let durationValue = duration {
            // Duration-based set
            if weight > 0 {
                // Weight + duration (e.g., Farmer's Walk)
                let weightStr = weight.truncatingRemainder(dividingBy: 1) == 0
                    ? "\(Int(weight))"
                    : String(format: "%.1f", weight)
                return "\(weightStr) × \(formatDuration(durationValue))"
            } else {
                // Duration only (e.g., Plank)
                return formatDuration(durationValue)
            }
        } else {
            // Weight × reps (standard)
            let weightStr = weight.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(weight))"
                : String(format: "%.1f", weight)
            return "\(weightStr) × \(reps)"
        }
    }

    /// Formats duration in seconds to "M:SS" format
    private func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    /// Duration display string
    var durationDisplay: String? {
        guard let durationValue = duration else { return nil }
        return formatDuration(durationValue)
    }

    /// Full display with optional tags
    var fullDisplay: String {
        var result = display
        if isWarmup {
            result += " (Warmup)"
        }
        if isDropset {
            result += " (Drop)"
        }
        if let rpeValue = rpe {
            result += " @RPE \(rpeValue)"
        }
        return result
    }

    /// RPE display string
    var rpeDisplay: String? {
        guard let rpeValue = rpe else { return nil }
        return "RPE \(rpeValue)"
    }

    /// Set type indicator
    var setType: SetType {
        if isWarmup {
            return .warmup
        }
        if isDropset {
            return .dropset
        }
        return .working
    }
}

// MARK: - Set Type

/// Type of set
enum SetType: String, Codable {
    case warmup
    case working
    case dropset

    var displayName: String {
        switch self {
        case .warmup:
            return "Warmup"
        case .working:
            return "Working"
        case .dropset:
            return "Drop Set"
        }
    }

    var shortName: String {
        switch self {
        case .warmup:
            return "W"
        case .working:
            return ""
        case .dropset:
            return "D"
        }
    }
}
