//
//  ExperienceLevel.swift
//  GymTrack Pro
//
//  Created by Claude Code on 27/01/26.
//

import Foundation

/// User's gym experience level
enum ExperienceLevel: String, Codable, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"

    /// Display name for UI
    var displayName: String {
        switch self {
        case .beginner:
            return "Beginner"
        case .intermediate:
            return "Intermediate"
        case .advanced:
            return "Advanced"
        }
    }

    /// Description of the experience level
    var description: String {
        switch self {
        case .beginner:
            return "New to lifting (0-6 months)"
        case .intermediate:
            return "Consistent training (6 months - 2 years)"
        case .advanced:
            return "Experienced lifter (2+ years)"
        }
    }

    /// Suggested rest time in seconds for this experience level
    var suggestedRestSeconds: Int {
        switch self {
        case .beginner:
            return 90
        case .intermediate:
            return 120
        case .advanced:
            return 180
        }
    }
}
