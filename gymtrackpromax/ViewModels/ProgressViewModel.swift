//
//  ProgressViewModel.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import Foundation
import SwiftData

// MARK: - Time Range

/// Time range options for filtering progress data
enum TimeRange: String, CaseIterable, Identifiable {
    case week = "1W"
    case month = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case year = "1Y"
    case all = "All"

    var id: String { rawValue }

    /// Number of days for this time range, nil for all time
    var days: Int? {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .sixMonths: return 180
        case .year: return 365
        case .all: return nil
        }
    }

    /// Display name for accessibility
    var displayName: String {
        switch self {
        case .week: return "1 Week"
        case .month: return "1 Month"
        case .threeMonths: return "3 Months"
        case .sixMonths: return "6 Months"
        case .year: return "1 Year"
        case .all: return "All Time"
        }
    }
}

// MARK: - Data Structures

/// Progress data for a single exercise
struct ExerciseProgress: Identifiable {
    let id = UUID()
    let exercise: Exercise
    let estimated1RM: Double
    let bestWeight: Double
    let bestReps: Int
    let totalSets: Int
    let recentDataPoints: [DataPoint]

    /// Single data point for sparkline
    struct DataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let estimated1RM: Double
    }
}

/// A personal record entry
struct PRRecord: Identifiable {
    let id = UUID()
    let exercise: Exercise
    let weight: Double
    let reps: Int
    let estimated1RM: Double
    let date: Date
    let sessionId: UUID?
}

/// Volume data point for chart
struct VolumeDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let volume: Double
}

/// Muscle group distribution data
struct MuscleDistribution: Identifiable {
    let id = UUID()
    let muscle: MuscleGroup
    let sets: Int
    let percentage: Double
}

// MARK: - Progress View Model

@Observable
@MainActor
final class ProgressViewModel {
    // MARK: - Properties

    private var modelContext: ModelContext

    // MARK: - State

    var selectedTimeRange: TimeRange = .month
    var isLoading: Bool = false
    var volumeData: [VolumeDataPoint] = []
    var topExercises: [ExerciseProgress] = []
    var personalRecords: [PRRecord] = []
    var totalVolumeInRange: Double = 0
    var workoutsInRange: Int = 0
    var prsInRange: Int = 0
    var muscleDistribution: [MuscleDistribution] = []

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Data Loading

    /// Load all progress data based on selected time range
    func loadProgressData(sessions: [WorkoutSession]) async {
        isLoading = true
        defer { isLoading = false }

        let filteredSessions = filterSessionsByTimeRange(sessions)

        // Calculate volume data
        volumeData = calculateVolumeData(sessions: filteredSessions)

        // Calculate top exercises
        topExercises = calculateTopExercises(sessions: filteredSessions, limit: 5)

        // Calculate personal records
        personalRecords = calculatePersonalRecords(sessions: sessions) // Use all sessions for PRs

        // Calculate summary stats
        totalVolumeInRange = filteredSessions.reduce(0) { $0 + $1.totalVolume }
        workoutsInRange = filteredSessions.count
        prsInRange = calculatePRsInRange(sessions: sessions, filteredSessions: filteredSessions)

        // Calculate muscle distribution
        muscleDistribution = calculateMuscleDistribution(sessions: filteredSessions)
    }

    // MARK: - Private Helpers

    /// Filter sessions based on selected time range
    private func filterSessionsByTimeRange(_ sessions: [WorkoutSession]) -> [WorkoutSession] {
        guard let days = selectedTimeRange.days else {
            // Return all completed sessions
            return sessions.filter { $0.isCompleted }
        }

        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return sessions.filter { session in
            session.isCompleted && session.startTime >= cutoffDate
        }
    }

    /// Calculate daily volume data points
    private func calculateVolumeData(sessions: [WorkoutSession]) -> [VolumeDataPoint] {
        let calendar = Calendar.current

        // Group sessions by day
        var volumeByDay: [Date: Double] = [:]

        for session in sessions {
            let dayStart = calendar.startOfDay(for: session.startTime)
            volumeByDay[dayStart, default: 0] += session.totalVolume
        }

        // Convert to sorted array of data points
        return volumeByDay
            .map { VolumeDataPoint(date: $0.key, volume: $0.value) }
            .sorted { $0.date < $1.date }
    }

    /// Calculate top exercises by estimated 1RM
    private func calculateTopExercises(sessions: [WorkoutSession], limit: Int) -> [ExerciseProgress] {
        // Collect all exercise logs grouped by exercise
        var exerciseData: [UUID: (exercise: Exercise, logs: [ExerciseLog])] = [:]

        for session in sessions {
            for log in session.exerciseLogs {
                guard let exercise = log.exercise else { continue }

                if exerciseData[exercise.id] == nil {
                    exerciseData[exercise.id] = (exercise: exercise, logs: [])
                }
                exerciseData[exercise.id]?.logs.append(log)
            }
        }

        // Calculate progress for each exercise
        var progressList: [ExerciseProgress] = []

        for (_, data) in exerciseData {
            let allSets = data.logs.flatMap { $0.workingSetsArray }
            guard !allSets.isEmpty else { continue }

            // Find best 1RM
            let best1RM = allSets.map { $0.estimated1RM }.max() ?? 0
            let bestWeight = allSets.map { $0.weight }.max() ?? 0
            let bestReps = allSets.map { $0.reps }.max() ?? 0
            let totalSets = allSets.count

            // Get recent data points for sparkline (last 10 sessions with this exercise)
            let recentLogs = data.logs
                .sorted { ($0.session?.startTime ?? Date.distantPast) > ($1.session?.startTime ?? Date.distantPast) }
                .prefix(10)

            let dataPoints = recentLogs.compactMap { log -> ExerciseProgress.DataPoint? in
                guard let session = log.session,
                      let best = log.bestSet else { return nil }
                return ExerciseProgress.DataPoint(
                    date: session.startTime,
                    estimated1RM: best.estimated1RM
                )
            }.reversed()

            progressList.append(ExerciseProgress(
                exercise: data.exercise,
                estimated1RM: best1RM,
                bestWeight: bestWeight,
                bestReps: bestReps,
                totalSets: totalSets,
                recentDataPoints: Array(dataPoints)
            ))
        }

        // Sort by estimated 1RM and take top N
        return progressList
            .sorted { $0.estimated1RM > $1.estimated1RM }
            .prefix(limit)
            .map { $0 }
    }

    /// Calculate all personal records
    private func calculatePersonalRecords(sessions: [WorkoutSession]) -> [PRRecord] {
        // Track best estimated 1RM for each exercise
        var bestByExercise: [UUID: (exercise: Exercise, weight: Double, reps: Int, estimated1RM: Double, date: Date, sessionId: UUID?)] = [:]

        // Sort sessions chronologically
        let sortedSessions = sessions.filter { $0.isCompleted }.sorted { $0.startTime < $1.startTime }

        for session in sortedSessions {
            for log in session.exerciseLogs {
                guard let exercise = log.exercise else { continue }

                for set in log.workingSetsArray {
                    let currentBest = bestByExercise[exercise.id]?.estimated1RM ?? 0

                    if set.estimated1RM > currentBest {
                        bestByExercise[exercise.id] = (
                            exercise: exercise,
                            weight: set.weight,
                            reps: set.reps,
                            estimated1RM: set.estimated1RM,
                            date: session.startTime,
                            sessionId: session.id
                        )
                    }
                }
            }
        }

        // Convert to PRRecord array and sort by date (most recent first)
        return bestByExercise.values
            .map { PRRecord(
                exercise: $0.exercise,
                weight: $0.weight,
                reps: $0.reps,
                estimated1RM: $0.estimated1RM,
                date: $0.date,
                sessionId: $0.sessionId
            )}
            .sorted { $0.date > $1.date }
    }

    /// Calculate number of PRs achieved within the filtered time range
    private func calculatePRsInRange(sessions: [WorkoutSession], filteredSessions: [WorkoutSession]) -> Int {
        // Get all session IDs in the filtered range
        let filteredSessionIds = Set(filteredSessions.map { $0.id })

        // Track PRs for each exercise up to each point in time
        var exercisePRs: [UUID: Double] = [:]
        var prsInRange = 0

        // Sort all sessions chronologically
        let sortedSessions = sessions.filter { $0.isCompleted }.sorted { $0.startTime < $1.startTime }

        for session in sortedSessions {
            for log in session.exerciseLogs {
                guard let exercise = log.exercise else { continue }

                for set in log.workingSetsArray {
                    let currentBest = exercisePRs[exercise.id] ?? 0

                    if set.estimated1RM > currentBest {
                        exercisePRs[exercise.id] = set.estimated1RM

                        // If this session is in the filtered range, count the PR
                        if filteredSessionIds.contains(session.id) {
                            prsInRange += 1
                        }
                    }
                }
            }
        }

        return prsInRange
    }

    /// Calculate muscle group distribution from working sets
    private func calculateMuscleDistribution(sessions: [WorkoutSession]) -> [MuscleDistribution] {
        var setsByMuscle: [MuscleGroup: Int] = [:]

        for session in sessions {
            for log in session.exerciseLogs {
                guard let muscle = log.exercise?.primaryMuscle else { continue }
                setsByMuscle[muscle, default: 0] += log.workingSets
            }
        }

        let totalSets = setsByMuscle.values.reduce(0, +)
        guard totalSets > 0 else { return [] }

        return setsByMuscle
            .map { muscle, sets in
                MuscleDistribution(
                    muscle: muscle,
                    sets: sets,
                    percentage: Double(sets) / Double(totalSets) * 100
                )
            }
            .sorted { $0.sets > $1.sets }
    }

    // MARK: - Formatting Helpers

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

    /// Format weight for display
    func formatWeight(_ weight: Double, unit: WeightUnit = .kg) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = weight.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 1
        return "\(formatter.string(from: NSNumber(value: weight)) ?? "0") \(unit.symbol)"
    }
}
