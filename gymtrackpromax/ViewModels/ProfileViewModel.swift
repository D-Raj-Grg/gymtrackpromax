//
//  ProfileViewModel.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import Foundation
import SwiftData

// MARK: - Lifetime Stats

/// Aggregated lifetime statistics for the user
struct LifetimeStats {
    var totalWorkouts: Int = 0
    var totalVolume: Double = 0
    var totalPRs: Int = 0
    var longestStreak: Int = 0
    var currentStreak: Int = 0
    var memberSinceDays: Int = 0
}

// MARK: - Profile View Model

@Observable
@MainActor
final class ProfileViewModel {
    // MARK: - Properties

    private var modelContext: ModelContext

    // MARK: - State

    var isLoading: Bool = false
    var lifetimeStats: LifetimeStats = LifetimeStats()
    var defaultRestTime: Int = WorkoutDefaults.restTimeSeconds
    var notificationsEnabled: Bool = false
    var showingClearDataAlert: Bool = false
    var showingExportSheet: Bool = false
    var exportedCSVURL: URL?
    var errorMessage: String?
    var showingError: Bool = false

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadUserPreferences()
    }

    // MARK: - User Preferences

    /// Load saved user preferences from UserDefaults
    private func loadUserPreferences() {
        let defaults = UserDefaults.standard
        defaultRestTime = defaults.integer(forKey: UserDefaultsKeys.defaultRestTime)
        if defaultRestTime == 0 {
            defaultRestTime = WorkoutDefaults.restTimeSeconds
        }
        notificationsEnabled = defaults.bool(forKey: UserDefaultsKeys.notificationsEnabled)
    }

    /// Save default rest time to UserDefaults
    func updateDefaultRestTime(_ seconds: Int) {
        defaultRestTime = seconds
        UserDefaults.standard.set(seconds, forKey: UserDefaultsKeys.defaultRestTime)
    }

    /// Toggle notifications and save to UserDefaults
    func toggleNotifications(_ enabled: Bool) {
        notificationsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: UserDefaultsKeys.notificationsEnabled)
    }

    // MARK: - Data Loading

    /// Load lifetime statistics for the user
    func loadLifetimeStats(user: User?, sessions: [WorkoutSession]) async {
        isLoading = true
        defer { isLoading = false }

        guard let user = user else { return }

        let completedSessions = sessions.filter { $0.isCompleted }

        // Total workouts
        lifetimeStats.totalWorkouts = completedSessions.count

        // Total volume
        lifetimeStats.totalVolume = completedSessions.reduce(0) { $0 + $1.totalVolume }

        // Total PRs (count unique exercise PRs)
        lifetimeStats.totalPRs = calculateTotalPRs(sessions: completedSessions)

        // Current streak
        lifetimeStats.currentStreak = user.currentStreak

        // Longest streak
        lifetimeStats.longestStreak = calculateLongestStreak(sessions: completedSessions)

        // Member since days
        let daysSinceJoined = Calendar.current.dateComponents([.day], from: user.createdAt, to: Date()).day ?? 0
        lifetimeStats.memberSinceDays = max(daysSinceJoined, 0)
    }

    // MARK: - Stats Calculations

    /// Calculate total unique personal records achieved
    private func calculateTotalPRs(sessions: [WorkoutSession]) -> Int {
        var exercisePRs: [UUID: Double] = [:]
        var totalPRs = 0

        // Sort sessions chronologically
        let sortedSessions = sessions.sorted { $0.startTime < $1.startTime }

        for session in sortedSessions {
            for log in session.exerciseLogs {
                guard let exercise = log.exercise else { continue }

                for set in log.sets where !set.isWarmup {
                    let currentBest = exercisePRs[exercise.id] ?? 0

                    if set.estimated1RM > currentBest {
                        exercisePRs[exercise.id] = set.estimated1RM
                        totalPRs += 1
                    }
                }
            }
        }

        return totalPRs
    }

    /// Calculate the longest workout streak ever achieved
    private func calculateLongestStreak(sessions: [WorkoutSession]) -> Int {
        guard !sessions.isEmpty else { return 0 }

        let calendar = Calendar.current

        // Get unique workout dates (sorted ascending)
        let workoutDates = Set(sessions.compactMap { session -> Date? in
            return calendar.startOfDay(for: session.startTime)
        }).sorted()

        guard !workoutDates.isEmpty else { return 0 }

        var longestStreak = 1
        var currentStreak = 1

        for i in 1..<workoutDates.count {
            let previousDate = workoutDates[i - 1]
            let currentDate = workoutDates[i]
            let daysDiff = calendar.dateComponents([.day], from: previousDate, to: currentDate).day ?? 0

            if daysDiff == 1 {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else if daysDiff > 1 {
                currentStreak = 1
            }
            // daysDiff == 0 means same day, keep currentStreak
        }

        return longestStreak
    }

    // MARK: - Data Export

    /// Export workout data to CSV format
    func exportDataToCSV(user: User?, sessions: [WorkoutSession]) {
        guard let user = user else {
            errorMessage = "No user data found"
            showingError = true
            return
        }

        var csvContent = "GymTrack Pro - Workout Export\n"
        csvContent += "User: \(user.name)\n"
        csvContent += "Export Date: \(formatDate(Date()))\n"
        csvContent += "Weight Unit: \(user.weightUnit.displayName)\n\n"

        // Headers
        csvContent += "Date,Workout Name,Duration (min),Total Volume (\(user.weightUnit.symbol)),Exercises,Sets\n"

        // Sort sessions by date
        let sortedSessions = sessions.filter { $0.isCompleted }.sorted { $0.startTime > $1.startTime }

        for session in sortedSessions {
            let date = formatDate(session.startTime)
            let workoutName = session.workoutName.replacingOccurrences(of: ",", with: ";")
            let durationMinutes = Int((session.duration ?? 0) / 60)
            let volume = Int(session.totalVolume)
            let exercises = session.exercisesCompleted
            let sets = session.totalSets

            csvContent += "\(date),\(workoutName),\(durationMinutes),\(volume),\(exercises),\(sets)\n"
        }

        // Add detailed exercise data
        csvContent += "\n\nDetailed Exercise Log\n"
        csvContent += "Date,Workout,Exercise,Set #,Weight (\(user.weightUnit.symbol)),Reps,Type,RPE\n"

        for session in sortedSessions {
            let date = formatDate(session.startTime)
            let workoutName = session.workoutName.replacingOccurrences(of: ",", with: ";")

            for log in session.sortedExerciseLogs {
                guard let exercise = log.exercise else { continue }
                let exerciseName = exercise.name.replacingOccurrences(of: ",", with: ";")

                for set in log.sets.sorted(by: { $0.setNumber < $1.setNumber }) {
                    let setType = set.setType.displayName
                    let rpeStr = set.rpe.map { "\($0)" } ?? ""

                    csvContent += "\(date),\(workoutName),\(exerciseName),\(set.setNumber),\(set.weight),\(set.reps),\(setType),\(rpeStr)\n"
                }
            }
        }

        // Save to temporary file
        let fileName = "GymTrackPro_Export_\(formatDateForFileName(Date())).csv"
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)

        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            exportedCSVURL = fileURL
            showingExportSheet = true
        } catch {
            errorMessage = "Failed to create export file: \(error.localizedDescription)"
            showingError = true
        }
    }

    // MARK: - Data Management

    /// Clear all user data after confirmation
    func clearAllData(user: User?) {
        guard let user = user else { return }

        // Delete all workout sessions
        for session in user.workoutSessions {
            modelContext.delete(session)
        }

        // Delete all workout splits
        for split in user.workoutSplits {
            modelContext.delete(split)
        }

        // Delete user
        modelContext.delete(user)

        // Clear UserDefaults
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: UserDefaultsKeys.hasCompletedOnboarding)
        defaults.removeObject(forKey: UserDefaultsKeys.defaultRestTime)
        defaults.removeObject(forKey: UserDefaultsKeys.notificationsEnabled)

        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to clear data: \(error.localizedDescription)"
            showingError = true
        }
    }

    // MARK: - Formatting Helpers

    /// Format date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = Foundation.DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    /// Format date for file name (no special characters)
    private func formatDateForFileName(_ date: Date) -> String {
        let formatter = Foundation.DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmm"
        return formatter.string(from: date)
    }

    /// Format volume for display
    func formatVolume(_ volume: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0

        if volume >= 1_000_000 {
            formatter.maximumFractionDigits = 1
            return "\(formatter.string(from: NSNumber(value: volume / 1_000_000)) ?? "0")M"
        } else if volume >= 1000 {
            formatter.maximumFractionDigits = 1
            return "\(formatter.string(from: NSNumber(value: volume / 1000)) ?? "0")k"
        }

        return formatter.string(from: NSNumber(value: volume)) ?? "0"
    }

    /// Format member since date
    func formatMemberSince(_ date: Date) -> String {
        let formatter = Foundation.DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    /// Get rest time options for picker
    var restTimeOptions: [Int] {
        [30, 45, 60, 90, 120, 150, 180, 240, 300]
    }

    /// Format rest time for display
    func formatRestTime(_ seconds: Int) -> String {
        if seconds >= 60 {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            if remainingSeconds == 0 {
                return "\(minutes) min"
            }
            return "\(minutes)m \(remainingSeconds)s"
        }
        return "\(seconds)s"
    }
}
