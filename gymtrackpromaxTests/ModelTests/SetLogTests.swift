//
//  SetLogTests.swift
//  gymtrackpromaxTests
//
//  Created by Claude Code on 30/01/26.
//

import Testing
import Foundation
@testable import gymtrackpromax

@Suite("SetLog Model Tests")
struct SetLogTests {

    @Test("Volume calculation is weight times reps")
    func testVolume() {
        let set = SetLog(setNumber: 1, weight: 100, reps: 10)
        #expect(set.volume == 1000)
    }

    @Test("Volume is zero when weight is zero")
    func testVolumeZeroWeight() {
        let set = SetLog(setNumber: 1, weight: 0, reps: 10)
        #expect(set.volume == 0)
    }

    @Test("Volume is zero when reps is zero")
    func testVolumeZeroReps() {
        let set = SetLog(setNumber: 1, weight: 100, reps: 0)
        #expect(set.volume == 0)
    }

    @Test("Estimated 1RM uses Epley formula")
    func testEstimated1RM() {
        let set = SetLog(setNumber: 1, weight: 100, reps: 10)
        // Epley: 100 * (1 + 10/30) = 100 * 1.333... = 133.33...
        let expected = 100.0 * (1.0 + 10.0 / 30.0)
        #expect(abs(set.estimated1RM - expected) < 0.01)
    }

    @Test("Estimated 1RM equals weight for single rep")
    func testEstimated1RMSingleRep() {
        let set = SetLog(setNumber: 1, weight: 150, reps: 1)
        #expect(set.estimated1RM == 150)
    }

    @Test("Estimated 1RM is zero for zero reps")
    func testEstimated1RMZeroReps() {
        let set = SetLog(setNumber: 1, weight: 100, reps: 0)
        #expect(set.estimated1RM == 0)
    }

    @Test("Display format for weight and reps")
    func testDisplay() {
        let set = SetLog(setNumber: 1, weight: 80, reps: 10)
        #expect(set.display == "80 × 10")
    }

    @Test("Display format with decimal weight")
    func testDisplayDecimalWeight() {
        let set = SetLog(setNumber: 1, weight: 82.5, reps: 8)
        #expect(set.display == "82.5 × 8")
    }

    @Test("Duration display format")
    func testDurationDisplay() {
        let set = SetLog(setNumber: 1, weight: 0, reps: 0, duration: 90)
        #expect(set.durationDisplay == "1:30")
    }

    @Test("Set type warmup")
    func testSetTypeWarmup() {
        let set = SetLog(setNumber: 1, weight: 40, reps: 10, isWarmup: true)
        #expect(set.setType == .warmup)
    }

    @Test("Set type working")
    func testSetTypeWorking() {
        let set = SetLog(setNumber: 1, weight: 100, reps: 10)
        #expect(set.setType == .working)
    }

    @Test("Set type dropset")
    func testSetTypeDropset() {
        let set = SetLog(setNumber: 1, weight: 80, reps: 12, isDropset: true)
        #expect(set.setType == .dropset)
    }

    @Test("Full display with tags")
    func testFullDisplay() {
        let set = SetLog(setNumber: 1, weight: 40, reps: 10, rpe: 7, isWarmup: true)
        #expect(set.fullDisplay.contains("Warmup"))
        #expect(set.fullDisplay.contains("RPE 7"))
    }
}
