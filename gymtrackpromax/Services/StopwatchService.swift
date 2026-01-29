//
//  StopwatchService.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import Foundation
import UIKit

/// Service for managing stopwatch with lap recording
@Observable
@MainActor
final class StopwatchService {
    // MARK: - Lap Model

    struct Lap: Identifiable {
        let id = UUID()
        let number: Int
        let lapTime: TimeInterval
        let totalTime: TimeInterval
    }

    // MARK: - Properties

    /// Whether the stopwatch is currently running
    private(set) var isRunning: Bool = false

    /// Total elapsed time in seconds
    private(set) var elapsedTime: TimeInterval = 0

    /// Recorded laps
    private(set) var laps: [Lap] = []

    /// Time at last lap
    private var lastLapTime: TimeInterval = 0

    /// Formatted elapsed time string (MM:SS.ms)
    var formattedTime: String {
        formatTime(elapsedTime)
    }

    /// Current lap time (since last lap)
    var currentLapTime: TimeInterval {
        elapsedTime - lastLapTime
    }

    /// Formatted current lap time
    var formattedLapTime: String {
        formatTime(currentLapTime)
    }

    // MARK: - Private Properties

    private var timer: Timer?
    private var startTime: Date?
    private var accumulatedTime: TimeInterval = 0
    private var backgroundTime: Date?

    // MARK: - Initialization

    init() {
        setupNotificationObservers()
    }

    // MARK: - Stopwatch Control

    /// Start the stopwatch
    func start() {
        guard !isRunning else { return }

        isRunning = true
        startTime = Date()
        startInternalTimer()
    }

    /// Stop/Pause the stopwatch
    func stop() {
        guard isRunning else { return }

        isRunning = false
        timer?.invalidate()
        timer = nil

        // Accumulate the time
        if let start = startTime {
            accumulatedTime += Date().timeIntervalSince(start)
        }
        startTime = nil
    }

    /// Record a lap
    func lap() {
        guard isRunning || elapsedTime > 0 else { return }

        let lapTime = elapsedTime - lastLapTime
        let lap = Lap(
            number: laps.count + 1,
            lapTime: lapTime,
            totalTime: elapsedTime
        )
        laps.insert(lap, at: 0)
        lastLapTime = elapsedTime

        HapticManager.buttonTap()
    }

    /// Reset the stopwatch
    func reset() {
        stop()
        elapsedTime = 0
        accumulatedTime = 0
        lastLapTime = 0
        laps.removeAll()
    }

    // MARK: - Internal Timer

    private func startInternalTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }

    private func tick() {
        guard isRunning, let start = startTime else { return }
        elapsedTime = accumulatedTime + Date().timeIntervalSince(start)
    }

    // MARK: - Time Formatting

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let centiseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, centiseconds)
    }

    // MARK: - Background Support

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.handleAppBackground()
            }
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.handleAppForeground()
            }
        }
    }

    private func handleAppBackground() {
        guard isRunning else { return }
        backgroundTime = Date()
        timer?.invalidate()
        timer = nil
    }

    private func handleAppForeground() {
        guard isRunning, let bgTime = backgroundTime else { return }
        backgroundTime = nil

        // Timer continues to accumulate based on startTime
        startInternalTimer()
    }
}
