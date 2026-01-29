//
//  ExerciseService.swift
//  GymTrack Pro
//
//  Created by Claude Code on 27/01/26.
//

import Foundation
import SwiftData

/// Service for managing exercise data
@MainActor
final class ExerciseService {
    // MARK: - Singleton

    static let shared = ExerciseService()

    private init() {}

    // MARK: - Seed Data

    /// Seeds the exercise database from JSON file
    /// - Parameter context: The SwiftData model context
    func seedExercises(context: ModelContext) async {
        guard let url = Bundle.main.url(forResource: "ExerciseData", withExtension: "json") else {
            print("ExerciseService: Could not find ExerciseData.json")
            // Use embedded exercises as fallback
            seedDefaultExercises(context: context)
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let exerciseDataList = try decoder.decode([ExerciseData].self, from: data)

            for exerciseData in exerciseDataList {
                if let exercise = exerciseData.toExercise() {
                    context.insert(exercise)
                }
            }

            try context.save()
            print("ExerciseService: Seeded \(exerciseDataList.count) exercises from JSON")
        } catch {
            print("ExerciseService: Error loading exercises from JSON: \(error)")
            // Fallback to default exercises
            seedDefaultExercises(context: context)
        }
    }

    /// Seeds default exercises without JSON file
    private func seedDefaultExercises(context: ModelContext) {
        let defaultExercises = createDefaultExercises()

        for exercise in defaultExercises {
            context.insert(exercise)
        }

        try? context.save()
        print("ExerciseService: Seeded \(defaultExercises.count) default exercises")
    }

    // MARK: - Default Exercises

    /// Creates default exercise list
    private func createDefaultExercises() -> [Exercise] {
        var exercises: [Exercise] = []

        // MARK: Chest Exercises
        exercises.append(contentsOf: [
            Exercise(name: "Barbell Bench Press", primaryMuscle: .chest, secondaryMuscles: [.triceps, .shoulders], equipment: .barbell),
            Exercise(name: "Incline Barbell Bench Press", primaryMuscle: .chest, secondaryMuscles: [.triceps, .shoulders], equipment: .barbell),
            Exercise(name: "Decline Barbell Bench Press", primaryMuscle: .chest, secondaryMuscles: [.triceps], equipment: .barbell),
            Exercise(name: "Dumbbell Bench Press", primaryMuscle: .chest, secondaryMuscles: [.triceps, .shoulders], equipment: .dumbbell),
            Exercise(name: "Incline Dumbbell Press", primaryMuscle: .chest, secondaryMuscles: [.triceps, .shoulders], equipment: .dumbbell),
            Exercise(name: "Dumbbell Fly", primaryMuscle: .chest, secondaryMuscles: [], equipment: .dumbbell),
            Exercise(name: "Incline Dumbbell Fly", primaryMuscle: .chest, secondaryMuscles: [], equipment: .dumbbell),
            Exercise(name: "Cable Fly", primaryMuscle: .chest, secondaryMuscles: [], equipment: .cable),
            Exercise(name: "Cable Crossover", primaryMuscle: .chest, secondaryMuscles: [], equipment: .cable),
            Exercise(name: "Chest Press Machine", primaryMuscle: .chest, secondaryMuscles: [.triceps], equipment: .machine),
            Exercise(name: "Pec Deck", primaryMuscle: .chest, secondaryMuscles: [], equipment: .machine),
            Exercise(name: "Push-Up", primaryMuscle: .chest, secondaryMuscles: [.triceps, .shoulders], equipment: .bodyweight),
        ])

        // MARK: Back Exercises
        exercises.append(contentsOf: [
            Exercise(name: "Barbell Row", primaryMuscle: .back, secondaryMuscles: [.biceps], equipment: .barbell),
            Exercise(name: "Pendlay Row", primaryMuscle: .back, secondaryMuscles: [.biceps], equipment: .barbell),
            Exercise(name: "Deadlift", primaryMuscle: .back, secondaryMuscles: [.hamstrings, .glutes], equipment: .barbell),
            Exercise(name: "Pull-Up", primaryMuscle: .back, secondaryMuscles: [.biceps], equipment: .bodyweight),
            Exercise(name: "Chin-Up", primaryMuscle: .back, secondaryMuscles: [.biceps], equipment: .bodyweight),
            Exercise(name: "Lat Pulldown", primaryMuscle: .back, secondaryMuscles: [.biceps], equipment: .cable),
            Exercise(name: "Close-Grip Lat Pulldown", primaryMuscle: .back, secondaryMuscles: [.biceps], equipment: .cable),
            Exercise(name: "Seated Cable Row", primaryMuscle: .back, secondaryMuscles: [.biceps], equipment: .cable),
            Exercise(name: "One-Arm Dumbbell Row", primaryMuscle: .back, secondaryMuscles: [.biceps], equipment: .dumbbell),
            Exercise(name: "T-Bar Row", primaryMuscle: .back, secondaryMuscles: [.biceps], equipment: .barbell),
            Exercise(name: "Chest Supported Row", primaryMuscle: .back, secondaryMuscles: [.biceps], equipment: .dumbbell),
            Exercise(name: "Face Pull", primaryMuscle: .back, secondaryMuscles: [.shoulders], equipment: .cable),
        ])

        // MARK: Shoulder Exercises
        exercises.append(contentsOf: [
            Exercise(name: "Overhead Press", primaryMuscle: .shoulders, secondaryMuscles: [.triceps], equipment: .barbell),
            Exercise(name: "Seated Dumbbell Press", primaryMuscle: .shoulders, secondaryMuscles: [.triceps], equipment: .dumbbell),
            Exercise(name: "Arnold Press", primaryMuscle: .shoulders, secondaryMuscles: [.triceps], equipment: .dumbbell),
            Exercise(name: "Lateral Raise", primaryMuscle: .shoulders, secondaryMuscles: [], equipment: .dumbbell),
            Exercise(name: "Cable Lateral Raise", primaryMuscle: .shoulders, secondaryMuscles: [], equipment: .cable),
            Exercise(name: "Front Raise", primaryMuscle: .shoulders, secondaryMuscles: [], equipment: .dumbbell),
            Exercise(name: "Reverse Fly", primaryMuscle: .shoulders, secondaryMuscles: [.back], equipment: .dumbbell),
            Exercise(name: "Cable Reverse Fly", primaryMuscle: .shoulders, secondaryMuscles: [.back], equipment: .cable),
            Exercise(name: "Upright Row", primaryMuscle: .shoulders, secondaryMuscles: [.biceps], equipment: .barbell),
            Exercise(name: "Shrugs", primaryMuscle: .shoulders, secondaryMuscles: [], equipment: .dumbbell),
        ])

        // MARK: Biceps Exercises
        exercises.append(contentsOf: [
            Exercise(name: "Barbell Curl", primaryMuscle: .biceps, secondaryMuscles: [.forearms], equipment: .barbell),
            Exercise(name: "EZ Bar Curl", primaryMuscle: .biceps, secondaryMuscles: [.forearms], equipment: .ezBar),
            Exercise(name: "Dumbbell Curl", primaryMuscle: .biceps, secondaryMuscles: [.forearms], equipment: .dumbbell),
            Exercise(name: "Hammer Curl", primaryMuscle: .biceps, secondaryMuscles: [.forearms], equipment: .dumbbell),
            Exercise(name: "Incline Dumbbell Curl", primaryMuscle: .biceps, secondaryMuscles: [], equipment: .dumbbell),
            Exercise(name: "Concentration Curl", primaryMuscle: .biceps, secondaryMuscles: [], equipment: .dumbbell),
            Exercise(name: "Preacher Curl", primaryMuscle: .biceps, secondaryMuscles: [], equipment: .ezBar),
            Exercise(name: "Cable Curl", primaryMuscle: .biceps, secondaryMuscles: [], equipment: .cable),
        ])

        // MARK: Triceps Exercises
        exercises.append(contentsOf: [
            Exercise(name: "Close-Grip Bench Press", primaryMuscle: .triceps, secondaryMuscles: [.chest], equipment: .barbell),
            Exercise(name: "Skull Crusher", primaryMuscle: .triceps, secondaryMuscles: [], equipment: .ezBar),
            Exercise(name: "Tricep Pushdown", primaryMuscle: .triceps, secondaryMuscles: [], equipment: .cable),
            Exercise(name: "Rope Pushdown", primaryMuscle: .triceps, secondaryMuscles: [], equipment: .cable),
            Exercise(name: "Overhead Tricep Extension", primaryMuscle: .triceps, secondaryMuscles: [], equipment: .dumbbell),
            Exercise(name: "Cable Overhead Extension", primaryMuscle: .triceps, secondaryMuscles: [], equipment: .cable),
            Exercise(name: "Dips", primaryMuscle: .triceps, secondaryMuscles: [.chest, .shoulders], equipment: .bodyweight),
            Exercise(name: "Diamond Push-Up", primaryMuscle: .triceps, secondaryMuscles: [.chest], equipment: .bodyweight),
        ])

        // MARK: Quad Exercises
        exercises.append(contentsOf: [
            Exercise(name: "Barbell Squat", primaryMuscle: .quads, secondaryMuscles: [.glutes, .hamstrings], equipment: .barbell),
            Exercise(name: "Front Squat", primaryMuscle: .quads, secondaryMuscles: [.glutes], equipment: .barbell),
            Exercise(name: "Leg Press", primaryMuscle: .quads, secondaryMuscles: [.glutes, .hamstrings], equipment: .machine),
            Exercise(name: "Hack Squat", primaryMuscle: .quads, secondaryMuscles: [.glutes], equipment: .machine),
            Exercise(name: "Leg Extension", primaryMuscle: .quads, secondaryMuscles: [], equipment: .machine),
            Exercise(name: "Bulgarian Split Squat", primaryMuscle: .quads, secondaryMuscles: [.glutes], equipment: .dumbbell),
            Exercise(name: "Goblet Squat", primaryMuscle: .quads, secondaryMuscles: [.glutes], equipment: .dumbbell),
            Exercise(name: "Walking Lunge", primaryMuscle: .quads, secondaryMuscles: [.glutes, .hamstrings], equipment: .dumbbell),
            Exercise(name: "Sissy Squat", primaryMuscle: .quads, secondaryMuscles: [], equipment: .bodyweight),
        ])

        // MARK: Hamstring Exercises
        exercises.append(contentsOf: [
            Exercise(name: "Romanian Deadlift", primaryMuscle: .hamstrings, secondaryMuscles: [.glutes, .back], equipment: .barbell),
            Exercise(name: "Stiff-Leg Deadlift", primaryMuscle: .hamstrings, secondaryMuscles: [.glutes], equipment: .barbell),
            Exercise(name: "Lying Leg Curl", primaryMuscle: .hamstrings, secondaryMuscles: [], equipment: .machine),
            Exercise(name: "Seated Leg Curl", primaryMuscle: .hamstrings, secondaryMuscles: [], equipment: .machine),
            Exercise(name: "Good Morning", primaryMuscle: .hamstrings, secondaryMuscles: [.glutes, .back], equipment: .barbell),
            Exercise(name: "Dumbbell RDL", primaryMuscle: .hamstrings, secondaryMuscles: [.glutes], equipment: .dumbbell),
            Exercise(name: "Nordic Hamstring Curl", primaryMuscle: .hamstrings, secondaryMuscles: [], equipment: .bodyweight),
        ])

        // MARK: Glute Exercises
        exercises.append(contentsOf: [
            Exercise(name: "Hip Thrust", primaryMuscle: .glutes, secondaryMuscles: [.hamstrings], equipment: .barbell),
            Exercise(name: "Glute Bridge", primaryMuscle: .glutes, secondaryMuscles: [.hamstrings], equipment: .bodyweight),
            Exercise(name: "Cable Kickback", primaryMuscle: .glutes, secondaryMuscles: [], equipment: .cable),
            Exercise(name: "Hip Abduction Machine", primaryMuscle: .glutes, secondaryMuscles: [], equipment: .machine),
            Exercise(name: "Sumo Deadlift", primaryMuscle: .glutes, secondaryMuscles: [.quads, .hamstrings], equipment: .barbell),
            Exercise(name: "Step-Up", primaryMuscle: .glutes, secondaryMuscles: [.quads], equipment: .dumbbell),
        ])

        // MARK: Calf Exercises
        exercises.append(contentsOf: [
            Exercise(name: "Standing Calf Raise", primaryMuscle: .calves, secondaryMuscles: [], equipment: .machine),
            Exercise(name: "Seated Calf Raise", primaryMuscle: .calves, secondaryMuscles: [], equipment: .machine),
            Exercise(name: "Leg Press Calf Raise", primaryMuscle: .calves, secondaryMuscles: [], equipment: .machine),
            Exercise(name: "Smith Machine Calf Raise", primaryMuscle: .calves, secondaryMuscles: [], equipment: .smithMachine),
            Exercise(name: "Single-Leg Calf Raise", primaryMuscle: .calves, secondaryMuscles: [], equipment: .bodyweight),
        ])

        // MARK: Abs Exercises
        exercises.append(contentsOf: [
            Exercise(name: "Crunch", primaryMuscle: .abs, secondaryMuscles: [], equipment: .bodyweight),
            Exercise(name: "Hanging Leg Raise", primaryMuscle: .abs, secondaryMuscles: [], equipment: .bodyweight),
            Exercise(name: "Cable Crunch", primaryMuscle: .abs, secondaryMuscles: [], equipment: .cable),
            Exercise(name: "Plank", primaryMuscle: .abs, secondaryMuscles: [], equipment: .bodyweight),
            Exercise(name: "Ab Wheel Rollout", primaryMuscle: .abs, secondaryMuscles: [], equipment: .bodyweight),
            Exercise(name: "Russian Twist", primaryMuscle: .abs, secondaryMuscles: [], equipment: .bodyweight),
            Exercise(name: "Bicycle Crunch", primaryMuscle: .abs, secondaryMuscles: [], equipment: .bodyweight),
            Exercise(name: "Leg Raise", primaryMuscle: .abs, secondaryMuscles: [], equipment: .bodyweight),
            Exercise(name: "Mountain Climber", primaryMuscle: .abs, secondaryMuscles: [], equipment: .bodyweight),
            Exercise(name: "Dead Bug", primaryMuscle: .abs, secondaryMuscles: [], equipment: .bodyweight),
        ])

        // MARK: Forearm Exercises
        exercises.append(contentsOf: [
            Exercise(name: "Wrist Curl", primaryMuscle: .forearms, secondaryMuscles: [], equipment: .barbell),
            Exercise(name: "Reverse Wrist Curl", primaryMuscle: .forearms, secondaryMuscles: [], equipment: .barbell),
            Exercise(name: "Farmer's Walk", primaryMuscle: .forearms, secondaryMuscles: [.shoulders], equipment: .dumbbell),
        ])

        return exercises
    }

    // MARK: - Query Methods

    /// Fetch all exercises
    func fetchAllExercises(context: ModelContext) -> [Exercise] {
        let descriptor = FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch exercises by muscle group
    func fetchExercises(forMuscle muscle: MuscleGroup, context: ModelContext) -> [Exercise] {
        let predicate = #Predicate<Exercise> { exercise in
            exercise.primaryMuscle == muscle
        }
        let descriptor = FetchDescriptor<Exercise>(predicate: predicate, sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch exercises by equipment
    func fetchExercises(forEquipment equipment: Equipment, context: ModelContext) -> [Exercise] {
        let predicate = #Predicate<Exercise> { exercise in
            exercise.equipment == equipment
        }
        let descriptor = FetchDescriptor<Exercise>(predicate: predicate, sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Search exercises by name
    func searchExercises(query: String, context: ModelContext) -> [Exercise] {
        let lowercaseQuery = query.lowercased()
        let predicate = #Predicate<Exercise> { exercise in
            exercise.name.localizedStandardContains(lowercaseQuery)
        }
        let descriptor = FetchDescriptor<Exercise>(predicate: predicate, sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch a single exercise by exact name
    func fetchExercise(byName name: String, context: ModelContext) -> Exercise? {
        let descriptor = FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.name)])
        guard let exercises = try? context.fetch(descriptor) else {
            return nil
        }
        return exercises.first { $0.name == name }
    }

    // MARK: - Custom Exercise CRUD

    /// Error types for exercise operations
    enum ExerciseError: LocalizedError {
        case duplicateName
        case emptyName
        case cannotEditDefaultExercise
        case cannotDeleteDefaultExercise
        case exerciseInUse
        case saveFailed(Error)

        var errorDescription: String? {
            switch self {
            case .duplicateName:
                return "An exercise with this name already exists"
            case .emptyName:
                return "Exercise name cannot be empty"
            case .cannotEditDefaultExercise:
                return "Cannot edit built-in exercises"
            case .cannotDeleteDefaultExercise:
                return "Cannot delete built-in exercises"
            case .exerciseInUse:
                return "Cannot delete exercise that is used in workout plans"
            case .saveFailed(let error):
                return "Failed to save: \(error.localizedDescription)"
            }
        }
    }

    /// Create a custom exercise
    /// - Parameters:
    ///   - name: Exercise name
    ///   - primaryMuscle: Primary muscle group targeted
    ///   - secondaryMuscles: Secondary muscle groups
    ///   - equipment: Equipment required
    ///   - instructions: Optional instructions
    ///   - context: SwiftData model context
    /// - Returns: The created exercise
    @discardableResult
    func createCustomExercise(
        name: String,
        primaryMuscle: MuscleGroup,
        secondaryMuscles: [MuscleGroup] = [],
        equipment: Equipment,
        instructions: String? = nil,
        context: ModelContext
    ) throws -> Exercise {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate name
        guard !trimmedName.isEmpty else {
            throw ExerciseError.emptyName
        }

        // Check for duplicates
        if exerciseExists(name: trimmedName, context: context) {
            throw ExerciseError.duplicateName
        }

        let exercise = Exercise(
            name: trimmedName,
            primaryMuscle: primaryMuscle,
            secondaryMuscles: secondaryMuscles,
            equipment: equipment,
            instructions: instructions?.trimmingCharacters(in: .whitespacesAndNewlines),
            isCustom: true
        )

        context.insert(exercise)

        do {
            try context.save()
            print("ExerciseService: Created custom exercise '\(trimmedName)'")
            return exercise
        } catch {
            throw ExerciseError.saveFailed(error)
        }
    }

    /// Update an existing custom exercise
    /// - Parameters:
    ///   - exercise: The exercise to update
    ///   - name: New name (optional)
    ///   - primaryMuscle: New primary muscle (optional)
    ///   - secondaryMuscles: New secondary muscles (optional)
    ///   - equipment: New equipment (optional)
    ///   - instructions: New instructions (optional)
    ///   - context: SwiftData model context
    func updateExercise(
        _ exercise: Exercise,
        name: String? = nil,
        primaryMuscle: MuscleGroup? = nil,
        secondaryMuscles: [MuscleGroup]? = nil,
        equipment: Equipment? = nil,
        instructions: String? = nil,
        context: ModelContext
    ) throws {
        // Only allow editing custom exercises
        guard exercise.isCustom else {
            throw ExerciseError.cannotEditDefaultExercise
        }

        // Update name if provided
        if let newName = name {
            let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !trimmedName.isEmpty else {
                throw ExerciseError.emptyName
            }

            // Check for duplicates (excluding current exercise)
            if trimmedName.lowercased() != exercise.name.lowercased() &&
               exerciseExists(name: trimmedName, context: context) {
                throw ExerciseError.duplicateName
            }

            exercise.name = trimmedName
        }

        // Update other fields
        if let primaryMuscle = primaryMuscle {
            exercise.primaryMuscle = primaryMuscle
        }

        if let secondaryMuscles = secondaryMuscles {
            exercise.secondaryMuscles = secondaryMuscles
        }

        if let equipment = equipment {
            exercise.equipment = equipment
        }

        if let instructions = instructions {
            exercise.instructions = instructions.isEmpty ? nil : instructions.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        do {
            try context.save()
            print("ExerciseService: Updated exercise '\(exercise.name)'")
        } catch {
            throw ExerciseError.saveFailed(error)
        }
    }

    /// Delete a custom exercise
    /// - Parameters:
    ///   - exercise: The exercise to delete
    ///   - context: SwiftData model context
    func deleteExercise(_ exercise: Exercise, context: ModelContext) throws {
        // Only allow deleting custom exercises
        guard exercise.isCustom else {
            throw ExerciseError.cannotDeleteDefaultExercise
        }

        // Check if exercise is used in any planned exercises
        let exerciseId = exercise.id
        let plannedDescriptor = FetchDescriptor<PlannedExercise>(
            predicate: #Predicate<PlannedExercise> { planned in
                planned.exercise?.id == exerciseId
            }
        )

        let plannedCount = (try? context.fetchCount(plannedDescriptor)) ?? 0
        if plannedCount > 0 {
            throw ExerciseError.exerciseInUse
        }

        let exerciseName = exercise.name
        context.delete(exercise)

        do {
            try context.save()
            print("ExerciseService: Deleted exercise '\(exerciseName)'")
        } catch {
            throw ExerciseError.saveFailed(error)
        }
    }

    /// Fetch all custom exercises
    func fetchCustomExercises(context: ModelContext) -> [Exercise] {
        let predicate = #Predicate<Exercise> { exercise in
            exercise.isCustom == true
        }
        let descriptor = FetchDescriptor<Exercise>(predicate: predicate, sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Check if an exercise with the given name exists
    private func exerciseExists(name: String, context: ModelContext) -> Bool {
        let lowercaseName = name.lowercased()
        let predicate = #Predicate<Exercise> { exercise in
            exercise.name.localizedStandardContains(lowercaseName)
        }
        let descriptor = FetchDescriptor<Exercise>(predicate: predicate)

        if let exercises = try? context.fetch(descriptor) {
            return exercises.contains { $0.name.lowercased() == lowercaseName }
        }
        return false
    }
}
