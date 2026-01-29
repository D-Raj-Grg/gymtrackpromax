//
//  FitnessGoal.swift
//  GymTrack Pro
//
//  Created by Claude Code on 27/01/26.
//

import Foundation

/// User's primary fitness goal
enum FitnessGoal: String, Codable, CaseIterable {
    case buildMuscle = "buildMuscle"
    case getStronger = "getStronger"
    case loseFat = "loseFat"
    case stayFit = "stayFit"

    /// Display name for UI
    var displayName: String {
        switch self {
        case .buildMuscle:
            return "Build Muscle"
        case .getStronger:
            return "Get Stronger"
        case .loseFat:
            return "Lose Fat"
        case .stayFit:
            return "Stay Fit"
        }
    }

    /// Description of the fitness goal
    var description: String {
        switch self {
        case .buildMuscle:
            return "Focus on hypertrophy and muscle growth"
        case .getStronger:
            return "Increase strength and lift heavier"
        case .loseFat:
            return "Burn calories and maintain muscle"
        case .stayFit:
            return "Maintain overall health and fitness"
        }
    }

    /// Icon name (SF Symbol)
    var iconName: String {
        switch self {
        case .buildMuscle:
            return "figure.strengthtraining.traditional"
        case .getStronger:
            return "dumbbell.fill"
        case .loseFat:
            return "flame.fill"
        case .stayFit:
            return "heart.fill"
        }
    }

    /// Suggested rep range for this goal
    var suggestedRepRange: ClosedRange<Int> {
        switch self {
        case .buildMuscle:
            return 8...12
        case .getStronger:
            return 3...6
        case .loseFat:
            return 12...15
        case .stayFit:
            return 8...12
        }
    }
}
