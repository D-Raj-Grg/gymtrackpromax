//
//  HapticManager.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import UIKit

/// Centralized haptic feedback manager for consistent haptic patterns throughout the app
enum HapticManager {
    // MARK: - Impact Feedback

    /// Trigger impact feedback
    /// - Parameter style: The intensity of the impact feedback
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Light impact - for button taps, toggles, selections
    static func lightImpact() {
        impact(.light)
    }

    /// Medium impact - for more significant actions
    static func mediumImpact() {
        impact(.medium)
    }

    /// Heavy impact - for major state changes
    static func heavyImpact() {
        impact(.heavy)
    }

    // MARK: - Notification Feedback

    /// Trigger notification feedback
    /// - Parameter type: The type of notification feedback
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    /// Success feedback - for completed actions, logged sets, achievements
    static func success() {
        notification(.success)
    }

    /// Warning feedback - for timer complete, approaching limits
    static func warning() {
        notification(.warning)
    }

    /// Error feedback - for failures, validation errors
    static func error() {
        notification(.error)
    }

    // MARK: - Selection Feedback

    /// Selection feedback - for picker changes, segment switches
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    // MARK: - Custom Patterns

    /// Double success haptic - for PRs and major achievements
    static func prAchieved() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            generator.notificationOccurred(.success)
        }
    }

    /// Timer complete haptic - warning pattern for rest timer
    static func timerComplete() {
        notification(.warning)
    }

    /// Workout complete haptic - celebratory pattern
    static func workoutComplete() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
    }

    /// Button tap haptic - standard button press
    static func buttonTap() {
        impact(.light)
    }

    /// Tab changed haptic - for tab bar navigation
    static func tabChanged() {
        selection()
    }

    /// Set logged haptic - for successfully logging a set
    static func setLogged() {
        success()
    }
}
