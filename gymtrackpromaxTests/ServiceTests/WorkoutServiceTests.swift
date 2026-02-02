//
//  WorkoutServiceTests.swift
//  gymtrackpromaxTests
//
//  Created by Claude Code on 30/01/26.
//

import Testing
import Foundation
import SwiftData
@testable import gymtrackpromax

@Suite("WorkoutService Tests")
@MainActor
struct WorkoutServiceTests {

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

    @Test("Start workout creates session with exercise logs")
    func testStartWorkout() throws {
        let context = try makeContext()
        let service = WorkoutService.shared

        let user = User(name: "Test", weightUnit: .kg, weekStartDay: .monday, experienceLevel: .beginner, fitnessGoal: .buildMuscle)
        context.insert(user)

        let exercise = Exercise(name: "Bench Press", primaryMuscle: .chest, secondaryMuscles: [], equipment: .barbell)
        context.insert(exercise)

        let day = WorkoutDay(name: "Push", dayOfWeek: 1, order: 0)
        context.insert(day)

        let planned = PlannedExercise(order: 0, targetSets: 3, targetRepsMin: 8, targetRepsMax: 12, restSeconds: 90)
        planned.exercise = exercise
        planned.workoutDay = day
        day.exercises.append(planned)
        context.insert(planned)

        let session = service.startWorkout(workoutDay: day, user: user, context: context)

        #expect(session.isInProgress)
        #expect(session.exerciseLogs.count == 1)
        #expect(session.exerciseLogs.first?.exercise?.name == "Bench Press")
    }

    @Test("Log set increments set count")
    func testLogSet() throws {
        let context = try makeContext()
        let service = WorkoutService.shared

        let log = ExerciseLog(exerciseOrder: 0)
        context.insert(log)

        let setLog = service.logSet(
            exerciseLog: log,
            weight: 80,
            reps: 10,
            duration: nil,
            rpe: 8,
            isWarmup: false,
            isDropset: false,
            context: context
        )

        #expect(setLog.setNumber == 1)
        #expect(setLog.weight == 80)
        #expect(setLog.reps == 10)
        #expect(log.sets.count == 1)
    }

    @Test("Delete set removes and renumbers")
    func testDeleteSet() throws {
        let context = try makeContext()
        let service = WorkoutService.shared

        let log = ExerciseLog(exerciseOrder: 0)
        context.insert(log)

        let set1 = service.logSet(exerciseLog: log, weight: 80, reps: 10, duration: nil, rpe: nil, isWarmup: false, isDropset: false, context: context)
        let _ = service.logSet(exerciseLog: log, weight: 80, reps: 8, duration: nil, rpe: nil, isWarmup: false, isDropset: false, context: context)

        #expect(log.sets.count == 2)

        service.deleteSet(set: set1, context: context)

        #expect(log.sets.count == 1)
        #expect(log.sets.first?.setNumber == 1)
    }

    @Test("Suggest weight returns most common recent weight")
    func testSuggestWeight() throws {
        let context = try makeContext()
        let service = WorkoutService.shared

        let user = User(name: "Test", weightUnit: .kg, weekStartDay: .monday, experienceLevel: .beginner, fitnessGoal: .buildMuscle)
        context.insert(user)

        let exercise = Exercise(name: "Squat", primaryMuscle: .quads, secondaryMuscles: [], equipment: .barbell)
        context.insert(exercise)

        // Create a completed session with sets
        let session = WorkoutSession(startTime: Date().addingTimeInterval(-3600), endTime: Date())
        session.user = user
        context.insert(session)

        let log = ExerciseLog(exerciseOrder: 0)
        log.exercise = exercise
        log.session = session
        session.exerciseLogs.append(log)
        context.insert(log)

        let set1 = SetLog(setNumber: 1, weight: 100, reps: 5)
        set1.exerciseLog = log
        log.sets.append(set1)
        context.insert(set1)

        let set2 = SetLog(setNumber: 2, weight: 100, reps: 5)
        set2.exerciseLog = log
        log.sets.append(set2)
        context.insert(set2)

        try context.save()

        let suggested = service.suggestWeight(for: exercise, user: user, context: context)
        #expect(suggested == 100)
    }
}
