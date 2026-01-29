//
//  DashboardViewModel.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import Foundation
import SwiftData

@Observable
@MainActor
final class DashboardViewModel {
    // MARK: - Properties

    private var modelContext: ModelContext

    // MARK: - Published State

    var workoutsThisWeek: Int = 0
    var volumeThisWeek: Double = 0
    var prsThisWeek: Int = 0
    var isLoading: Bool = false

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Data Loading

    func loadWeeklyStats() async {
        isLoading = true
        defer { isLoading = false }

        let calendar = Calendar.current
        let today = Date()

        // Get start of week (Sunday)
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return
        }

        // Fetch completed sessions this week
        let predicate = #Predicate<WorkoutSession> { session in
            session.endTime != nil && session.startTime >= weekStart
        }

        let descriptor = FetchDescriptor<WorkoutSession>(predicate: predicate)

        do {
            let sessions = try modelContext.fetch(descriptor)

            // Calculate stats
            workoutsThisWeek = sessions.count
            volumeThisWeek = sessions.reduce(0) { $0 + $1.totalVolume }

            // PRs this week - placeholder (will be fully implemented in Milestone 1.6)
            // For now, we'd need to compare each set to historical bests
            prsThisWeek = 0

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
