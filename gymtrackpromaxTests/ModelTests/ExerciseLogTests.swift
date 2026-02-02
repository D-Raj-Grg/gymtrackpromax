//
//  ExerciseLogTests.swift
//  gymtrackpromaxTests
//
//  Created by Claude Code on 30/01/26.
//

import Testing
import Foundation
@testable import gymtrackpromax

@Suite("ExerciseLog Model Tests")
struct ExerciseLogTests {

    @Test("Working sets excludes warmups")
    func testWorkingSets() {
        let log = ExerciseLog(exerciseOrder: 0)
        let warmup = SetLog(setNumber: 1, weight: 40, reps: 10, isWarmup: true)
        warmup.exerciseLog = log
        let working1 = SetLog(setNumber: 2, weight: 80, reps: 10)
        working1.exerciseLog = log
        let working2 = SetLog(setNumber: 3, weight: 80, reps: 8)
        working2.exerciseLog = log

        log.sets = [warmup, working1, working2]

        #expect(log.workingSets == 2)
        #expect(log.workingSetsArray.count == 2)
    }

    @Test("Best set by estimated 1RM")
    func testBestSet() {
        let log = ExerciseLog(exerciseOrder: 0)
        let set1 = SetLog(setNumber: 1, weight: 80, reps: 10) // 1RM ~106.7
        set1.exerciseLog = log
        let set2 = SetLog(setNumber: 2, weight: 90, reps: 5)  // 1RM ~105
        set2.exerciseLog = log

        log.sets = [set1, set2]

        #expect(log.bestSet?.id == set1.id)
    }

    @Test("Total volume for working sets only")
    func testTotalVolume() {
        let log = ExerciseLog(exerciseOrder: 0)
        let warmup = SetLog(setNumber: 1, weight: 40, reps: 10, isWarmup: true)
        warmup.exerciseLog = log
        let working = SetLog(setNumber: 2, weight: 80, reps: 10)
        working.exerciseLog = log

        log.sets = [warmup, working]

        #expect(log.totalVolume == 800) // Only working set: 80 * 10
    }

    @Test("Max weight across all sets")
    func testMaxWeight() {
        let log = ExerciseLog(exerciseOrder: 0)
        let set1 = SetLog(setNumber: 1, weight: 60, reps: 10)
        set1.exerciseLog = log
        let set2 = SetLog(setNumber: 2, weight: 80, reps: 8)
        set2.exerciseLog = log

        log.sets = [set1, set2]

        #expect(log.maxWeight == 80)
    }

    @Test("Max reps across all sets")
    func testMaxReps() {
        let log = ExerciseLog(exerciseOrder: 0)
        let set1 = SetLog(setNumber: 1, weight: 60, reps: 12)
        set1.exerciseLog = log
        let set2 = SetLog(setNumber: 2, weight: 80, reps: 8)
        set2.exerciseLog = log

        log.sets = [set1, set2]

        #expect(log.maxReps == 12)
    }

    @Test("Exercise name defaults to Unknown Exercise")
    func testDefaultExerciseName() {
        let log = ExerciseLog(exerciseOrder: 0)
        #expect(log.exerciseName == "Unknown Exercise")
    }

    @Test("Empty exercise log has no best set")
    func testBestSetEmpty() {
        let log = ExerciseLog(exerciseOrder: 0)
        #expect(log.bestSet == nil)
    }

    @Test("Sorted sets by set number")
    func testSortedSets() {
        let log = ExerciseLog(exerciseOrder: 0)
        let set3 = SetLog(setNumber: 3, weight: 80, reps: 8)
        set3.exerciseLog = log
        let set1 = SetLog(setNumber: 1, weight: 60, reps: 10)
        set1.exerciseLog = log
        let set2 = SetLog(setNumber: 2, weight: 70, reps: 9)
        set2.exerciseLog = log

        log.sets = [set3, set1, set2]

        let sorted = log.sortedSets
        #expect(sorted[0].setNumber == 1)
        #expect(sorted[1].setNumber == 2)
        #expect(sorted[2].setNumber == 3)
    }
}
