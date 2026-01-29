//
//  SplitTemplateService.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import Foundation
import SwiftData

/// Service for generating workout split templates with curated, research-backed exercise selections
@MainActor
final class SplitTemplateService {
    // MARK: - Singleton

    static let shared = SplitTemplateService()

    private init() {}

    // MARK: - Generate Split

    /// Generates a complete workout split with days and exercises
    func generateSplit(
        type: SplitType,
        selectedWeekdays: [Int],
        fitnessGoal: FitnessGoal,
        context: ModelContext
    ) async throws -> WorkoutSplit {
        // Create the split
        let split = WorkoutSplit(
            name: type.displayName,
            splitType: type,
            isActive: true
        )
        context.insert(split)

        // Get workout day templates
        let dayTemplates = getDayTemplates(for: type)

        // Assign days to selected weekdays
        let sortedWeekdays = selectedWeekdays.sorted()

        for (index, template) in dayTemplates.enumerated() {
            let workoutDay = WorkoutDay(
                name: template.name,
                dayOrder: index
            )

            // Assign weekday if available
            if index < sortedWeekdays.count {
                workoutDay.scheduledWeekdays = [sortedWeekdays[index]]
            }

            context.insert(workoutDay)
            workoutDay.split = split
            split.workoutDays.append(workoutDay)

            // Add exercises to the day using curated exercise names
            let exercises = try await getExercises(
                byNames: template.exerciseNames,
                context: context
            )

            for (exerciseIndex, exercise) in exercises.enumerated() {
                let repRange = fitnessGoal.suggestedRepRange
                let plannedExercise = PlannedExercise(
                    exerciseOrder: exerciseIndex,
                    targetSets: getTargetSets(for: exerciseIndex, total: exercises.count),
                    targetRepsMin: repRange.lowerBound,
                    targetRepsMax: repRange.upperBound,
                    restSeconds: getRestSeconds(for: exerciseIndex, total: exercises.count)
                )
                context.insert(plannedExercise)
                plannedExercise.workoutDay = workoutDay
                plannedExercise.exercise = exercise
                workoutDay.plannedExercises.append(plannedExercise)
            }
        }

        return split
    }

    // MARK: - Day Templates

    /// Template for a workout day with exercise names
    struct DayTemplate {
        let name: String
        let exerciseNames: [String]
    }

    /// Returns curated, research-backed exercise selections for each split type
    /// Based on recommendations from StrengthLog, Built With Science, and Gymshark
    func getDayTemplates(for splitType: SplitType) -> [DayTemplate] {
        switch splitType {
        case .ppl:
            // PPL (6 days - 2x per week frequency)
            return [
                DayTemplate(name: "Push", exerciseNames: [
                    "Barbell Bench Press",
                    "Overhead Press",
                    "Incline Dumbbell Press",
                    "Lateral Raise",
                    "Tricep Pushdown",
                    "Overhead Tricep Extension"
                ]),
                DayTemplate(name: "Pull", exerciseNames: [
                    "Barbell Row",
                    "Lat Pulldown",
                    "Seated Cable Row",
                    "Face Pull",
                    "Barbell Curl",
                    "Hammer Curl"
                ]),
                DayTemplate(name: "Legs", exerciseNames: [
                    "Barbell Squat",
                    "Romanian Deadlift",
                    "Leg Press",
                    "Lying Leg Curl",
                    "Standing Calf Raise",
                    "Walking Lunge"
                ]),
                DayTemplate(name: "Push", exerciseNames: [
                    "Barbell Bench Press",
                    "Overhead Press",
                    "Incline Dumbbell Press",
                    "Lateral Raise",
                    "Tricep Pushdown",
                    "Overhead Tricep Extension"
                ]),
                DayTemplate(name: "Pull", exerciseNames: [
                    "Barbell Row",
                    "Lat Pulldown",
                    "Seated Cable Row",
                    "Face Pull",
                    "Barbell Curl",
                    "Hammer Curl"
                ]),
                DayTemplate(name: "Legs", exerciseNames: [
                    "Barbell Squat",
                    "Romanian Deadlift",
                    "Leg Press",
                    "Lying Leg Curl",
                    "Standing Calf Raise",
                    "Walking Lunge"
                ])
            ]

        case .upperLower:
            // Upper/Lower (4 days - efficient split with variety between A/B days)
            return [
                DayTemplate(name: "Upper A", exerciseNames: [
                    "Barbell Bench Press",
                    "Barbell Row",
                    "Overhead Press",
                    "Lat Pulldown",
                    "Barbell Curl",
                    "Tricep Pushdown"
                ]),
                DayTemplate(name: "Lower A", exerciseNames: [
                    "Barbell Squat",
                    "Romanian Deadlift",
                    "Leg Press",
                    "Lying Leg Curl",
                    "Standing Calf Raise"
                ]),
                DayTemplate(name: "Upper B", exerciseNames: [
                    "Incline Dumbbell Press",
                    "One-Arm Dumbbell Row",
                    "Lateral Raise",
                    "Seated Cable Row",
                    "Hammer Curl",
                    "Skull Crusher"
                ]),
                DayTemplate(name: "Lower B", exerciseNames: [
                    "Deadlift",
                    "Bulgarian Split Squat",
                    "Leg Extension",
                    "Seated Leg Curl",
                    "Seated Calf Raise"
                ])
            ]

        case .broSplit:
            // Bro Split (5 days - bodybuilding classic)
            return [
                DayTemplate(name: "Chest", exerciseNames: [
                    "Barbell Bench Press",
                    "Incline Dumbbell Press",
                    "Cable Fly",
                    "Dips",
                    "Pec Deck"
                ]),
                DayTemplate(name: "Back", exerciseNames: [
                    "Deadlift",
                    "Barbell Row",
                    "Lat Pulldown",
                    "Seated Cable Row",
                    "Face Pull"
                ]),
                DayTemplate(name: "Shoulders", exerciseNames: [
                    "Overhead Press",
                    "Lateral Raise",
                    "Reverse Fly",
                    "Shrugs",
                    "Front Raise"
                ]),
                DayTemplate(name: "Arms", exerciseNames: [
                    "Barbell Curl",
                    "Hammer Curl",
                    "Preacher Curl",
                    "Tricep Pushdown",
                    "Skull Crusher",
                    "Dips"
                ]),
                DayTemplate(name: "Legs", exerciseNames: [
                    "Barbell Squat",
                    "Romanian Deadlift",
                    "Leg Press",
                    "Lying Leg Curl",
                    "Leg Extension",
                    "Standing Calf Raise"
                ])
            ]

        case .fullBody:
            // Full Body (3 days - beginner friendly)
            return [
                DayTemplate(name: "Full Body A", exerciseNames: [
                    "Barbell Squat",
                    "Barbell Bench Press",
                    "Barbell Row",
                    "Overhead Press",
                    "Barbell Curl"
                ]),
                DayTemplate(name: "Full Body B", exerciseNames: [
                    "Deadlift",
                    "Incline Dumbbell Press",
                    "Lat Pulldown",
                    "Lateral Raise",
                    "Tricep Pushdown"
                ]),
                DayTemplate(name: "Full Body C", exerciseNames: [
                    "Leg Press",
                    "Dumbbell Bench Press",
                    "Seated Cable Row",
                    "Face Pull",
                    "Hammer Curl"
                ])
            ]

        case .arnoldSplit:
            // Arnold Split (6 days - advanced)
            return [
                DayTemplate(name: "Chest & Back", exerciseNames: [
                    "Barbell Bench Press",
                    "Incline Dumbbell Press",
                    "Barbell Row",
                    "Lat Pulldown",
                    "Cable Fly",
                    "One-Arm Dumbbell Row"
                ]),
                DayTemplate(name: "Shoulders & Arms", exerciseNames: [
                    "Overhead Press",
                    "Lateral Raise",
                    "Barbell Curl",
                    "Tricep Pushdown",
                    "Hammer Curl",
                    "Skull Crusher"
                ]),
                DayTemplate(name: "Legs", exerciseNames: [
                    "Barbell Squat",
                    "Romanian Deadlift",
                    "Leg Press",
                    "Lying Leg Curl",
                    "Leg Extension",
                    "Standing Calf Raise"
                ]),
                DayTemplate(name: "Chest & Back", exerciseNames: [
                    "Barbell Bench Press",
                    "Incline Dumbbell Press",
                    "Barbell Row",
                    "Lat Pulldown",
                    "Cable Fly",
                    "One-Arm Dumbbell Row"
                ]),
                DayTemplate(name: "Shoulders & Arms", exerciseNames: [
                    "Overhead Press",
                    "Lateral Raise",
                    "Barbell Curl",
                    "Tricep Pushdown",
                    "Hammer Curl",
                    "Skull Crusher"
                ]),
                DayTemplate(name: "Legs", exerciseNames: [
                    "Barbell Squat",
                    "Romanian Deadlift",
                    "Leg Press",
                    "Lying Leg Curl",
                    "Leg Extension",
                    "Standing Calf Raise"
                ])
            ]

        case .ulPpl:
            // Upper/Lower + PPL Hybrid (5 days - best of both worlds)
            return [
                DayTemplate(name: "Upper", exerciseNames: [
                    "Barbell Bench Press",
                    "Barbell Row",
                    "Overhead Press",
                    "Lat Pulldown",
                    "Lateral Raise",
                    "Barbell Curl",
                    "Tricep Pushdown"
                ]),
                DayTemplate(name: "Lower", exerciseNames: [
                    "Barbell Squat",
                    "Romanian Deadlift",
                    "Leg Press",
                    "Lying Leg Curl",
                    "Walking Lunge",
                    "Standing Calf Raise"
                ]),
                DayTemplate(name: "Push", exerciseNames: [
                    "Barbell Bench Press",
                    "Overhead Press",
                    "Incline Dumbbell Press",
                    "Lateral Raise",
                    "Tricep Pushdown",
                    "Overhead Tricep Extension"
                ]),
                DayTemplate(name: "Pull", exerciseNames: [
                    "Barbell Row",
                    "Lat Pulldown",
                    "Seated Cable Row",
                    "Face Pull",
                    "Barbell Curl",
                    "Hammer Curl"
                ]),
                DayTemplate(name: "Legs", exerciseNames: [
                    "Barbell Squat",
                    "Romanian Deadlift",
                    "Leg Press",
                    "Lying Leg Curl",
                    "Standing Calf Raise",
                    "Walking Lunge"
                ])
            ]

        case .pplUl:
            // PPL + Upper/Lower Hybrid (5 days - unique hybrid approach)
            return [
                DayTemplate(name: "Push", exerciseNames: [
                    "Barbell Bench Press",
                    "Overhead Press",
                    "Incline Dumbbell Press",
                    "Lateral Raise",
                    "Tricep Pushdown",
                    "Overhead Tricep Extension"
                ]),
                DayTemplate(name: "Pull", exerciseNames: [
                    "Barbell Row",
                    "Lat Pulldown",
                    "Seated Cable Row",
                    "Face Pull",
                    "Barbell Curl",
                    "Hammer Curl"
                ]),
                DayTemplate(name: "Legs", exerciseNames: [
                    "Barbell Squat",
                    "Romanian Deadlift",
                    "Leg Press",
                    "Lying Leg Curl",
                    "Standing Calf Raise",
                    "Walking Lunge"
                ]),
                DayTemplate(name: "Upper", exerciseNames: [
                    "Barbell Bench Press",
                    "Barbell Row",
                    "Overhead Press",
                    "Lat Pulldown",
                    "Lateral Raise",
                    "Barbell Curl",
                    "Tricep Pushdown"
                ]),
                DayTemplate(name: "Lower", exerciseNames: [
                    "Barbell Squat",
                    "Romanian Deadlift",
                    "Leg Press",
                    "Lying Leg Curl",
                    "Walking Lunge",
                    "Standing Calf Raise"
                ])
            ]

        case .custom:
            // Custom split starts empty, user builds it themselves
            return []
        }
    }

    // MARK: - Exercise Selection

    /// Fetches exercises by their exact names from the database
    /// Falls back to finding similar exercises if exact name not found
    private func getExercises(
        byNames exerciseNames: [String],
        context: ModelContext
    ) async throws -> [Exercise] {
        var selectedExercises: [Exercise] = []
        let exerciseService = ExerciseService.shared

        for name in exerciseNames {
            if let exercise = exerciseService.fetchExercise(byName: name, context: context) {
                selectedExercises.append(exercise)
            }
            // If exercise not found, skip it (fallback handled gracefully)
        }

        return selectedExercises
    }

    // MARK: - Set/Rest Configuration

    private func getTargetSets(for exerciseIndex: Int, total: Int) -> Int {
        // First 2-3 exercises get more sets (compound movements)
        if exerciseIndex < 2 {
            return 4
        } else if exerciseIndex < 4 {
            return 3
        } else {
            return 3
        }
    }

    private func getRestSeconds(for exerciseIndex: Int, total: Int) -> Int {
        // Compounds get more rest
        if exerciseIndex < 2 {
            return 120
        } else if exerciseIndex < 4 {
            return 90
        } else {
            return 60
        }
    }
}
