//
//  Constants.swift
//  GymTrack Pro
//
//  Created by Claude Code on 27/01/26.
//

import Foundation
import SwiftUI

// MARK: - Spacing

/// Standard spacing values used throughout the app
enum AppSpacing {
    /// Extra small spacing (4px)
    static let xs: CGFloat = 4

    /// Small spacing (8px)
    static let small: CGFloat = 8

    /// Component gap spacing (12px)
    static let component: CGFloat = 12

    /// Standard padding (16px)
    static let standard: CGFloat = 16

    /// Card padding (20px)
    static let card: CGFloat = 20

    /// Section spacing (24px)
    static let section: CGFloat = 24

    /// Large spacing (32px)
    static let large: CGFloat = 32

    /// Extra large spacing (48px)
    static let xl: CGFloat = 48
}

// MARK: - Corner Radius

/// Corner radius values used throughout the app
enum AppCornerRadius {
    /// Small elements (8px)
    static let small: CGFloat = 8

    /// Buttons and inputs (12px)
    static let button: CGFloat = 12

    /// Input fields (12px)
    static let input: CGFloat = 12

    /// Cards (16px)
    static let card: CGFloat = 16

    /// Large cards (20px)
    static let cardLarge: CGFloat = 20

    /// Full rounded (for circular elements)
    static let full: CGFloat = 9999
}

// MARK: - Animation

/// Animation duration values
enum AppAnimation {
    /// Quick animations (0.15s)
    static let quick: Double = 0.15

    /// Standard animations (0.25s)
    static let standard: Double = 0.25

    /// Slow animations (0.35s)
    static let slow: Double = 0.35

    /// Spring animation
    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.7)

    /// Bounce animation
    static let bounce = Animation.spring(response: 0.4, dampingFraction: 0.6)

    /// Reorder spring animation - snappy for drag-to-reorder displacement
    static let reorderSpring = Animation.spring(response: 0.3, dampingFraction: 0.75)
}

// MARK: - Workout Defaults

/// Default values for workouts
enum WorkoutDefaults {
    /// Default rest time in seconds
    static let restTimeSeconds: Int = 90

    /// Default target sets
    static let targetSets: Int = 3

    /// Default min reps
    static let minReps: Int = 8

    /// Default max reps
    static let maxReps: Int = 12

    /// Weight increment for barbell (kg)
    static let weightIncrementKg: Double = 0.5

    /// Weight increment for dumbbell (kg)
    static let dumbbellIncrementKg: Double = 0.5
}

// MARK: - App Constants

/// General app constants
enum AppConstants {
    /// App name
    static let appName = "GymTrack Pro"

    /// App version (fetched from bundle)
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    /// Build number
    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    /// Maximum RPE value
    static let maxRPE: Int = 10

    /// Minimum RPE value
    static let minRPE: Int = 1

    /// Maximum workout duration in hours
    static let maxWorkoutDurationHours: Int = 4
}

// MARK: - UserDefaults Keys

/// Keys for UserDefaults storage
enum UserDefaultsKeys {
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let defaultRestTime = "defaultRestTime"
    static let notificationsEnabled = "notificationsEnabled"
    static let lastOpenedDate = "lastOpenedDate"
    static let preferredWeightUnit = "preferredWeightUnit"
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when a workout is started
    static let workoutStarted = Notification.Name("workoutStarted")

    /// Posted when a workout is completed
    static let workoutCompleted = Notification.Name("workoutCompleted")

    /// Posted when a PR is achieved
    static let prAchieved = Notification.Name("prAchieved")

    /// Posted when rest timer completes
    static let restTimerCompleted = Notification.Name("restTimerCompleted")

    /// Posted when user taps rest timer notification
    static let restTimerNotificationTapped = Notification.Name("restTimerNotificationTapped")

    /// Posted when a workout day is edited while a session is in progress
    static let workoutDayEdited = Notification.Name("workoutDayEdited")
}
