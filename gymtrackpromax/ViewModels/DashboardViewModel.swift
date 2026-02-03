//
//  DashboardViewModel.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import Foundation
import SwiftData

/// Info for a recent PR to display on the dashboard
struct DashboardPRInfo: Identifiable {
    let id = UUID()
    let exerciseName: String
    let weight: Double
    let reps: Int
    let estimated1RM: Double
    let date: Date
}

@Observable
@MainActor
final class DashboardViewModel {
    // MARK: - Properties

    private var modelContext: ModelContext

    // MARK: - Published State

    var workoutsThisWeek: Int = 0
    var volumeThisWeek: Double = 0
    var prsThisWeek: Int = 0
    var recentPRs: [DashboardPRInfo] = []
    var isLoading: Bool = false

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Data Loading

    // MARK: - PR Cache

    /// Cached all-time best 1RM per exercise (exercise ID → best 1RM)
    private static var cachedExerciseBests: [UUID: (exerciseName: String, estimated1RM: Double, weight: Double, reps: Int, date: Date)] = [:]
    private static var cachedSessionCount: Int = 0

    func loadWeeklyStats() async {
        isLoading = true
        defer { isLoading = false }

        let calendar = Calendar.current
        let today = Date()

        // Get start of week (Sunday)
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return
        }

        do {
            // Fetch only this week's sessions for workout count/volume
            let weeklyPredicate = #Predicate<WorkoutSession> { session in
                session.endTime != nil && session.startTime >= weekStart
            }
            let weeklyDescriptor = FetchDescriptor<WorkoutSession>(
                predicate: weeklyPredicate,
                sortBy: [SortDescriptor(\.startTime)]
            )
            let weeklySessions = try modelContext.fetch(weeklyDescriptor)
            workoutsThisWeek = weeklySessions.count
            volumeThisWeek = weeklySessions.reduce(0) { $0 + $1.totalVolume }

            // Fetch all completed sessions for PR calculation (use cache if unchanged)
            let allPredicate = #Predicate<WorkoutSession> { session in
                session.endTime != nil
            }
            let allDescriptor = FetchDescriptor<WorkoutSession>(
                predicate: allPredicate,
                sortBy: [SortDescriptor(\.startTime)]
            )
            let allSessions = try modelContext.fetch(allDescriptor)

            // Rebuild PR cache only if session count changed
            if allSessions.count != Self.cachedSessionCount {
                Self.cachedExerciseBests.removeAll()
                Self.cachedSessionCount = allSessions.count

                for session in allSessions {
                    for log in session.exerciseLogs {
                        guard let exercise = log.exercise else { continue }
                        for set in log.workingSetsArray {
                            let currentBest = Self.cachedExerciseBests[exercise.id]?.estimated1RM ?? 0
                            if set.estimated1RM > currentBest {
                                Self.cachedExerciseBests[exercise.id] = (
                                    exerciseName: exercise.name,
                                    estimated1RM: set.estimated1RM,
                                    weight: set.weight,
                                    reps: set.reps,
                                    date: session.startTime
                                )
                            }
                        }
                    }
                }
            }

            // Calculate PRs in this week using cached bests
            let weeklySessionIds = Set(weeklySessions.map { $0.id })
            var exerciseBests: [UUID: Double] = [:]
            var prCount = 0
            var prList: [DashboardPRInfo] = []

            for session in allSessions {
                for log in session.exerciseLogs {
                    guard let exercise = log.exercise else { continue }
                    for set in log.workingSetsArray {
                        let currentBest = exerciseBests[exercise.id] ?? 0
                        if set.estimated1RM > currentBest {
                            exerciseBests[exercise.id] = set.estimated1RM
                            if weeklySessionIds.contains(session.id) {
                                prCount += 1
                                prList.append(DashboardPRInfo(
                                    exerciseName: exercise.name,
                                    weight: set.weight,
                                    reps: set.reps,
                                    estimated1RM: set.estimated1RM,
                                    date: session.startTime
                                ))
                            }
                        }
                    }
                }
            }

            prsThisWeek = prCount
            recentPRs = Array(prList.sorted { $0.date > $1.date }.prefix(3))

        } catch {
            print("Error fetching weekly stats: \(error)")
        }
    }

    // MARK: - Formatting

    var volumeDisplayString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0

        if volumeThisWeek >= 1000 {
            formatter.maximumFractionDigits = 1
            let inThousands = volumeThisWeek / 1000
            return "\(formatter.string(from: NSNumber(value: inThousands)) ?? "0")k"
        }

        return formatter.string(from: NSNumber(value: volumeThisWeek)) ?? "0"
    }
}
