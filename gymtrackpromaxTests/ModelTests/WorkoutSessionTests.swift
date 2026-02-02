//
//  WorkoutSessionTests.swift
//  gymtrackpromaxTests
//
//  Created by Claude Code on 30/01/26.
//

import Testing
import Foundation
@testable import gymtrackpromax

@Suite("WorkoutSession Model Tests")
struct WorkoutSessionTests {

    @Test("Session is in progress when endTime is nil")
    func testIsInProgress() {
        let session = WorkoutSession(startTime: Date())
        #expect(session.isInProgress)
        #expect(!session.isCompleted)
    }

    @Test("Session is completed when endTime is set")
    func testIsCompleted() {
        let session = WorkoutSession(startTime: Date(), endTime: Date())
        #expect(session.isCompleted)
        #expect(!session.isInProgress)
    }

    @Test("Duration calculated correctly")
    func testDuration() {
        let start = Date()
        let end = start.addingTimeInterval(3600) // 1 hour
        let session = WorkoutSession(startTime: start, endTime: end)
        #expect(session.duration == 3600)
    }

    @Test("Duration is nil when in progress")
    func testDurationNil() {
        let session = WorkoutSession(startTime: Date())
        #expect(session.duration == nil)
    }

    @Test("Duration display for short workout")
    func testDurationDisplayShort() {
        let start = Date()
        let end = start.addingTimeInterval(45 * 60) // 45 minutes
        let session = WorkoutSession(startTime: start, endTime: end)
        #expect(session.durationDisplay == "45m")
    }

    @Test("Duration display for long workout")
    func testDurationDisplayLong() {
        let start = Date()
        let end = start.addingTimeInterval(90 * 60) // 1h 30m
        let session = WorkoutSession(startTime: start, endTime: end)
        #expect(session.durationDisplay == "1h 30m")
    }

    @Test("Duration display for in-progress")
    func testDurationDisplayInProgress() {
        let session = WorkoutSession(startTime: Date())
        #expect(session.durationDisplay == "In Progress")
    }

    @Test("Default workout name")
    func testDefaultWorkoutName() {
        let session = WorkoutSession(startTime: Date())
        #expect(session.workoutName == "Quick Workout")
    }

    @Test("Total volume with no exercises")
    func testTotalVolumeEmpty() {
        let session = WorkoutSession(startTime: Date())
        #expect(session.totalVolume == 0)
    }

    @Test("Working sets count with no exercises")
    func testWorkingSetsEmpty() {
        let session = WorkoutSession(startTime: Date())
        #expect(session.workingSets == 0)
    }
}
