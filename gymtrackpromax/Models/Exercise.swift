//
//  Exercise.swift
//  GymTrack Pro
//
//  Created by Claude Code on 27/01/26.
//

import Foundation
import SwiftData

/// An exercise definition
@Model
final class Exercise {
    // MARK: - Properties

    var id: UUID
    var name: String
    var primaryMuscle: MuscleGroup
    var secondaryMuscles: [MuscleGroup]
    var equipment: Equipment
    var exerciseType: ExerciseType
    var instructions: String?
    var isCustom: Bool

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        primaryMuscle: MuscleGroup,
        secondaryMuscles: [MuscleGroup] = [],
        equipment: Equipment,
        exerciseType: ExerciseType = .weightAndReps,
        instructions: String? = nil,
        isCustom: Bool = false
    ) {
        self.id = id
        self.name = name
        self.primaryMuscle = primaryMuscle
        self.secondaryMuscles = secondaryMuscles
        self.equipment = equipment
        self.exerciseType = exerciseType
        self.instructions = instructions
        self.isCustom = isCustom
    }

    // MARK: - Computed Properties

    /// All muscle groups targeted by this exercise
    var allMuscles: [MuscleGroup] {
        [primaryMuscle] + secondaryMuscles
    }

    /// Whether this is a compound exercise (targets multiple muscle groups)
    var isCompound: Bool {
        !secondaryMuscles.isEmpty
    }

    /// Push/Pull/Legs category
    var pplCategory: PPLCategory {
        primaryMuscle.pplCategory
    }

    /// Body region
    var bodyRegion: BodyRegion {
        primaryMuscle.bodyRegion
    }

    /// Standard weight increment for this exercise
    var weightIncrement: Double {
        equipment.standardIncrementKg
    }

    /// Display string for muscle groups
    var musclesDisplay: String {
        if secondaryMuscles.isEmpty {
            return primaryMuscle.displayName
        }
        let secondary = secondaryMuscles.map { $0.displayName }.joined(separator: ", ")
        return "\(primaryMuscle.displayName) • \(secondary)"
    }
}

// MARK: - Exercise for JSON Decoding

/// Struct for decoding exercises from JSON
struct ExerciseData: Codable {
    let name: String
    let primaryMuscle: String
    let secondaryMuscles: [String]
    let equipment: String
    let exerciseType: String?
    let instructions: String?

    func toExercise() -> Exercise? {
        guard let primary = MuscleGroup(rawValue: primaryMuscle),
              let equip = Equipment(rawValue: equipment) else {
            return nil
        }

        let secondary = secondaryMuscles.compactMap { MuscleGroup(rawValue: $0) }
        let type = exerciseType.flatMap { ExerciseType(rawValue: $0) } ?? .weightAndReps

        return Exercise(
            name: name,
            primaryMuscle: primary,
            secondaryMuscles: secondary,
            equipment: equip,
            exerciseType: type,
            instructions: instructions,
            isCustom: false
        )
    }
}
