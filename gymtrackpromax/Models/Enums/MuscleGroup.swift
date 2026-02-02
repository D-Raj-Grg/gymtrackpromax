//
//  MuscleGroup.swift
//  GymTrack Pro
//
//  Created by Claude Code on 27/01/26.
//

import Foundation

/// Target muscle groups for exercises
enum MuscleGroup: String, Codable, CaseIterable {
    case chest = "chest"
    case back = "back"
    case shoulders = "shoulders"
    case biceps = "biceps"
    case triceps = "triceps"
    case quads = "quads"
    case hamstrings = "hamstrings"
    case glutes = "glutes"
    case calves = "calves"
    case abs = "abs"
    case forearms = "forearms"

    /// Display name for UI
    var displayName: String {
        switch self {
        case .chest:
            return "Chest"
        case .back:
            return "Back"
        case .shoulders:
            return "Shoulders"
        case .biceps:
            return "Biceps"
        case .triceps:
            return "Triceps"
        case .quads:
            return "Quads"
        case .hamstrings:
            return "Hamstrings"
        case .glutes:
            return "Glutes"
        case .calves:
            return "Calves"
        case .abs:
            return "Abs"
        case .forearms:
            return "Forearms"
        }
    }

    /// Icon name (SF Symbol)
    var iconName: String {
        switch self {
        case .chest:
            return "figure.arms.open"
        case .back:
            return "figure.indoor.rowing"
        case .shoulders:
            return "figure.boxing"
        case .biceps:
            return "figure.strengthtraining.traditional"
        case .triceps:
            return "figure.strengthtraining.functional"
        case .quads:
            return "figure.step.training"
        case .hamstrings:
            return "figure.run"
        case .glutes:
            return "figure.stair.stepper"
        case .calves:
            return "figure.walk"
        case .abs:
            return "figure.core.training"
        case .forearms:
            return "figure.hand.cycling"
        }
    }

    /// Body region grouping
    var bodyRegion: BodyRegion {
        switch self {
        case .chest, .back, .shoulders:
            return .upper
        case .biceps, .triceps, .forearms:
            return .arms
        case .quads, .hamstrings, .glutes, .calves:
            return .lower
        case .abs:
            return .core
        }
    }

    /// Push/Pull/Legs classification
    var pplCategory: PPLCategory {
        switch self {
        case .chest, .shoulders, .triceps:
            return .push
        case .back, .biceps, .forearms:
            return .pull
        case .quads, .hamstrings, .glutes, .calves:
            return .legs
        case .abs:
            return .core
        }
    }
}

/// Body region for grouping muscle groups
enum BodyRegion: String, Codable, CaseIterable {
    case upper = "upper"
    case lower = "lower"
    case arms = "arms"
    case core = "core"

    var displayName: String {
        switch self {
        case .upper:
            return "Upper Body"
        case .lower:
            return "Lower Body"
        case .arms:
            return "Arms"
        case .core:
            return "Core"
        }
    }
}

/// Push/Pull/Legs category
enum PPLCategory: String, Codable, CaseIterable {
    case push = "push"
    case pull = "pull"
    case legs = "legs"
    case core = "core"

    var displayName: String {
        switch self {
        case .push:
            return "Push"
        case .pull:
            return "Pull"
        case .legs:
            return "Legs"
        case .core:
            return "Core"
        }
    }
}
