//
//  TimerService.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import Foundation
import UserNotifications
import UIKit

/// Service for managing rest timer with background support
@Observable
@MainActor
final class TimerService {
    // MARK: - Properties

    /// Whether the timer is currently running
    private(set) var isRunning: Bool = false

    /// Whether the timer is paused
    private(set) var isPaused: Bool = false

    /// Remaining time in seconds
    private(set) var remainingTime: TimeInterval = 0

    /// Total duration of the timer
    private(set) var totalDuration: TimeInterval = 0

    /// Progress (0.0 to 1.0)
    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1.0 - (remainingTime / totalDuration)
    }

    /// Formatted remaining time string
    var formattedTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Whether timer has completed
    private(set) var isCompleted: Bool = false

    // MARK: - Private Properties

    private var timer: Timer?
    private var backgroundTime: Date?
    private var notificationIdentifier = "rest-timer-notification"

    // MARK: - Initialization

    init() {
        setupNotificationObservers()
    }

    // MARK: - Timer Control

    /// Start the timer with a duration
    func start(duration: TimeInterval) {
        stop()

        totalDuration = duration
        remainingTime = duration
        isRunning = true
        isPaused = false
        isCompleted = false

        startInternalTimer()
    }

    /// Pause the timer
    func pause() {
        guard isRunning && !isPaused else { return }

        isPaused = true
        timer?.invalidate()
        timer = nil

        // Cancel any scheduled notification
        cancelNotification()
    }

    /// Resume the timer
    func resume() {
        guard isRunning && isPaused else { return }

        isPaused = false
        startInternalTimer()
    }

    /// Add time to the timer
    func addTime(_ seconds: TimeInterval) {
        remainingTime += seconds
        totalDuration += seconds

        // Reschedule notification if running in background
        if isRunning && !isPaused {
            scheduleRestCompleteNotification(in: remainingTime)
        }
    }

    /// Skip the timer
    func skip() {
        stop()
        isCompleted = true
        postCompletionNotification()
    }

    /// Stop the timer
    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        remainingTime = 0
        totalDuration = 0

        cancelNotification()
    }

    // MARK: - Internal Timer

    private func startInternalTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }

    private func tick() {
        guard isRunning && !isPaused else { return }

        remainingTime -= 1

        if remainingTime <= 0 {
            remainingTime = 0
            completeTimer()
        }
    }

    private func completeTimer() {
        stop()
        isCompleted = true

        // Haptic feedback
        HapticManager.timerComplete()

        // Post notification
        postCompletionNotification()
    }

    private func postCompletionNotification() {
        NotificationCenter.default.post(name: .restTimerCompleted, object: nil)
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

    /// Handle app going to background
    func handleAppBackground() {
        guard isRunning && !isPaused else { return }

        // Store the time when going to background
        backgroundTime = Date()

        // Stop the internal timer
        timer?.invalidate()
        timer = nil

        // Schedule local notification
        scheduleRestCompleteNotification(in: remainingTime)
    }

    /// Handle app coming to foreground
    func handleAppForeground() {
        guard isRunning, let bgTime = backgroundTime else { return }

        // Calculate elapsed time
        let elapsed = Date().timeIntervalSince(bgTime)
        backgroundTime = nil

        // Cancel the scheduled notification
        cancelNotification()

        // Update remaining time
        remainingTime = max(0, remainingTime - elapsed)

        // Check if timer completed while in background
        if remainingTime <= 0 {
            remainingTime = 0
            completeTimer()
        } else if !isPaused {
            // Resume internal timer
            startInternalTimer()
        }
    }

    // MARK: - Notifications

    /// Request notification permission
    func requestNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }

    /// Schedule a rest complete notification
    func scheduleRestCompleteNotification(in seconds: TimeInterval) {
        let center = UNUserNotificationCenter.current()

        // Cancel any existing notification
        center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])

        guard seconds > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Rest Complete!"
        content.body = "Time to get back to your workout."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: seconds,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    /// Cancel scheduled notification
    func cancelNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
    }
}
