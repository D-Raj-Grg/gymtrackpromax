//
//  Equipment.swift
//  GymTrack Pro
//
//  Created by Claude Code on 27/01/26.
//

import Foundation

/// Equipment types for exercises
enum Equipment: String, Codable, CaseIterable {
    case barbell = "barbell"
    case dumbbell = "dumbbell"
    case cable = "cable"
    case machine = "machine"
    case bodyweight = "bodyweight"
    case kettlebell = "kettlebell"
    case ezBar = "ezBar"
    case smithMachine = "smithMachine"
    case resistanceBand = "resistanceBand"
    case trapBar = "trapBar"

    /// Display name for UI
    var displayName: String {
        switch self {
        case .barbell:
            return "Barbell"
        case .dumbbell:
            return "Dumbbell"
        case .cable:
            return "Cable"
        case .machine:
            return "Machine"
        case .bodyweight:
            return "Bodyweight"
        case .kettlebell:
            return "Kettlebell"
        case .ezBar:
            return "EZ Bar"
        case .smithMachine:
            return "Smith Machine"
        case .resistanceBand:
            return "Resistance Band"
        case .trapBar:
            return "Trap Bar"
        }
    }

    /// Icon name (SF Symbol)
    var iconName: String {
        switch self {
        case .barbell:
            return "dumbbell.fill"
        case .dumbbell:
            return "dumbbell"
        case .cable:
            return "arrow.up.and.down"
        case .machine:
            return "gearshape.fill"
        case .bodyweight:
            return "figure.stand"
        case .kettlebell:
            return "drop.fill"
        case .ezBar:
            return "waveform"
        case .smithMachine:
            return "arrow.up.and.down.square"
        case .resistanceBand:
            return "wind"
        case .trapBar:
            return "hexagon.fill"
        }
    }

    /// Whether this equipment typically requires a spotter
    var requiresSpotter: Bool {
        switch self {
        case .barbell, .smithMachine:
            return true
        default:
            return false
        }
    }

    /// Standard weight increments in kg
    var standardIncrementKg: Double {
        switch self {
        case .bodyweight, .resistanceBand:
            return 0
        default:
            return 0.5
        }
    }
}
