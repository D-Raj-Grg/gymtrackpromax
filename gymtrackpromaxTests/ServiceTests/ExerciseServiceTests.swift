//
//  ExerciseServiceTests.swift
//  gymtrackpromaxTests
//
//  Created by Claude Code on 30/01/26.
//

import Testing
import Foundation
import SwiftData
@testable import gymtrackpromax

@Suite("ExerciseService Tests")
@MainActor
struct ExerciseServiceTests {

    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: User.self, WorkoutSplit.self, WorkoutDay.self,
                 Exercise.self, PlannedExercise.self,
                 WorkoutSession.self, ExerciseLog.self, SetLog.self,
            configurations: config
        )
        return container.mainContext
    }

    @Test("Create custom exercise succeeds")
    func testCreateCustomExercise() throws {
        let context = try makeContext()
        let service = ExerciseService.shared

        let exercise = try service.createCustomExercise(
            name: "My Custom Exercise",
            primaryMuscle: .chest,
            secondaryMuscles: [.triceps],
            equipment: .dumbbell,
            context: context
        )

        #expect(exercise.name == "My Custom Exercise")
        #expect(exercise.primaryMuscle == .chest)
        #expect(exercise.isCustom == true)
    }

    @Test("Create exercise with empty name throws")
    func testCreateExerciseEmptyName() throws {
        let context = try makeContext()
        let service = ExerciseService.shared

        #expect(throws: ExerciseService.ExerciseError.self) {
            try service.createCustomExercise(
                name: "  ",
                primaryMuscle: .chest,
                equipment: .barbell,
                context: context
            )
        }
    }

    @Test("Create duplicate exercise throws")
    func testCreateDuplicateExercise() throws {
        let context = try makeContext()
        let service = ExerciseService.shared

        _ = try service.createCustomExercise(
            name: "Unique Exercise",
            primaryMuscle: .back,
            equipment: .cable,
            context: context
        )

        #expect(throws: ExerciseService.ExerciseError.self) {
            try service.createCustomExercise(
                name: "Unique Exercise",
                primaryMuscle: .back,
                equipment: .cable,
                context: context
            )
        }
    }

    @Test("Delete custom exercise succeeds")
    func testDeleteCustomExercise() throws {
        let context = try makeContext()
        let service = ExerciseService.shared

        let exercise = try service.createCustomExercise(
            name: "To Delete",
            primaryMuscle: .shoulders,
            equipment: .dumbbell,
            context: context
        )

        try service.deleteExercise(exercise, context: context)

        let all = service.fetchAllExercises(context: context)
        #expect(!all.contains { $0.name == "To Delete" })
    }

    @Test("Delete non-custom exercise throws")
    func testDeleteDefaultExercise() throws {
        let context = try makeContext()
        let service = ExerciseService.shared

        let exercise = Exercise(name: "Built-in", primaryMuscle: .chest, secondaryMuscles: [], equipment: .barbell)
        context.insert(exercise)
        try context.save()

        #expect(throws: ExerciseService.ExerciseError.self) {
            try service.deleteExercise(exercise, context: context)
        }
    }

    @Test("Search exercises by name")
    func testSearchExercises() throws {
        let context = try makeContext()
        let service = ExerciseService.shared

        let e1 = Exercise(name: "Bench Press", primaryMuscle: .chest, secondaryMuscles: [], equipment: .barbell)
        let e2 = Exercise(name: "Squat", primaryMuscle: .quads, secondaryMuscles: [], equipment: .barbell)
        context.insert(e1)
        context.insert(e2)
        try context.save()

        let results = service.searchExercises(query: "bench", context: context)
        #expect(results.count == 1)
        #expect(results.first?.name == "Bench Press")
    }

    @Test("Fetch exercises by muscle group")
    func testFetchByMuscle() throws {
        let context = try makeContext()
        let service = ExerciseService.shared

        let chest = Exercise(name: "Fly", primaryMuscle: .chest, secondaryMuscles: [], equipment: .dumbbell)
        let back = Exercise(name: "Row", primaryMuscle: .back, secondaryMuscles: [], equipment: .barbell)
        context.insert(chest)
        context.insert(back)
        try context.save()

        let results = service.fetchExercises(forMuscle: .chest, context: context)
        #expect(results.count == 1)
        #expect(results.first?.name == "Fly")
    }
}
