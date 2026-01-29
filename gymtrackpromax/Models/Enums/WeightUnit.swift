//
//  WeightUnit.swift
//  GymTrack Pro
//
//  Created by Claude Code on 27/01/26.
//

import Foundation

/// Unit of measurement for weights
enum WeightUnit: String, Codable, CaseIterable {
    case kg = "kg"
    case lbs = "lbs"

    /// Display name for UI
    var displayName: String {
        switch self {
        case .kg:
            return "Kilograms (kg)"
        case .lbs:
            return "Pounds (lbs)"
        }
    }

    /// Short symbol for compact display
    var symbol: String {
        rawValue
    }

    /// Conversion factor to kilograms
    var toKgFactor: Double {
        switch self {
        case .kg:
            return 1.0
        case .lbs:
            return 0.453592
        }
    }

    /// Convert a value to the other unit
    func convert(_ value: Double, to targetUnit: WeightUnit) -> Double {
        if self == targetUnit {
            return value
        }
        // Convert to kg first, then to target
        let inKg = value * self.toKgFactor
        return inKg / targetUnit.toKgFactor
    }
}
