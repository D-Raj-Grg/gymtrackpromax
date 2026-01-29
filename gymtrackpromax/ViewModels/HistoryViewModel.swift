//
//  HistoryViewModel.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import Foundation
import SwiftData

@Observable
@MainActor
final class HistoryViewModel {
    // MARK: - Properties

    private var modelContext: ModelContext

    // MARK: - Published State

    var selectedDate: Date?
    var selectedMonth: Date = Date()
    var isLoading: Bool = false

    // Cached data
    private var cachedSessions: [WorkoutSession] = []
    private var maxMonthlyVolume: Double = 0

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Data Loading

    /// Load all sessions for the current month
    func loadSessionsForMonth() async {
        isLoading = true
        defer { isLoading = false }

        let calendar = Calendar.current

        // Get start and end of the selected month
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth)),
              let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
            return
        }

        // Create end of day for month end
        let monthEndEndOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: monthEnd) ?? monthEnd

        let predicate = #Predicate<WorkoutSession> { session in
            session.startTime >= monthStart && session.startTime <= monthEndEndOfDay
        }

        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        do {
            cachedSessions = try modelContext.fetch(descriptor)
            calculateMaxVolume()
        } catch {
            print("Error fetching sessions for month: \(error)")
            cachedSessions = []
        }
    }

    /// Calculate the maximum daily volume for intensity scaling
    private func calculateMaxVolume() {
        let calendar = Calendar.current
        var volumeByDay: [Date: Double] = [:]

        for session in cachedSessions where session.isCompleted {
            let dayStart = calendar.startOfDay(for: session.startTime)
            volumeByDay[dayStart, default: 0] += session.totalVolume
        }

        maxMonthlyVolume = volumeByDay.values.max() ?? 0
    }

    // MARK: - Public Accessors

    /// Get all sessions grouped by day for the selected month
    func workoutsForMonth() -> [Date: [WorkoutSession]] {
        let calendar = Calendar.current
        var grouped: [Date: [WorkoutSession]] = [:]

        for session in cachedSessions where session.isCompleted {
            let dayStart = calendar.startOfDay(for: session.startTime)
            grouped[dayStart, default: []].append(session)
        }

        return grouped
    }

    /// Get sessions for a specific date
    func workoutsForDate(_ date: Date) -> [WorkoutSession] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)

        return cachedSessions.filter { session in
            session.isCompleted && calendar.startOfDay(for: session.startTime) == dayStart
        }
    }

    /// Get all completed sessions, optionally filtered by selected date
    func filteredSessions() -> [WorkoutSession] {
        if let selectedDate = selectedDate {
            return workoutsForDate(selectedDate)
        }
        return cachedSessions.filter { $0.isCompleted }
    }

    /// Calculate workout intensity for a specific date (0-1 scale)
    func workoutIntensity(for date: Date) -> Double {
        guard maxMonthlyVolume > 0 else { return 0 }

        let sessions = workoutsForDate(date)
        guard !sessions.isEmpty else { return 0 }

        let totalVolume = sessions.reduce(0) { $0 + $1.totalVolume }

        // Return intensity between 0.3 and 1.0 for any workout day
        // This ensures even light workouts are visible
        let normalizedIntensity = totalVolume / maxMonthlyVolume
        return 0.3 + (normalizedIntensity * 0.7)
    }

    /// Check if a date has any workouts
    func hasWorkout(on date: Date) -> Bool {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)

        return cachedSessions.contains { session in
            session.isCompleted && calendar.startOfDay(for: session.startTime) == dayStart
        }
    }

    // MARK: - Actions

    /// Delete a workout session
    func deleteWorkout(_ session: WorkoutSession) {
        modelContext.delete(session)

        do {
            try modelContext.save()
            // Remove from cached sessions
            cachedSessions.removeAll { $0.id == session.id }
            calculateMaxVolume()
        } catch {
            print("Error deleting workout: \(error)")
        }
    }

    /// Navigate to previous month
    func goToPreviousMonth() {
        let calendar = Calendar.current
        if let previousMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = previousMonth
            selectedDate = nil
        }
    }

    /// Navigate to next month
    func goToNextMonth() {
        let calendar = Calendar.current
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) {
            selectedMonth = nextMonth
            selectedDate = nil
        }
    }

    /// Select or deselect a date
    func toggleDateSelection(_ date: Date) {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)

        if let currentSelection = selectedDate,
           calendar.startOfDay(for: currentSelection) == dayStart {
            // Deselect if already selected
            selectedDate = nil
        } else {
            selectedDate = dayStart
        }
    }

    /// Clear date selection
    func clearSelection() {
        selectedDate = nil
    }

    // MARK: - Formatting

    /// Format the month/year display
    var monthYearDisplay: String {
        let formatter = Foundation.DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    /// Check if can navigate to next month (don't go beyond current month)
    var canGoToNextMonth: Bool {
        let calendar = Calendar.current
        let currentMonth = calendar.dateComponents([.year, .month], from: Date())
        let selectedMonthComponents = calendar.dateComponents([.year, .month], from: selectedMonth)

        if let currentYear = currentMonth.year,
           let currentMonthNum = currentMonth.month,
           let selectedYear = selectedMonthComponents.year,
           let selectedMonthNum = selectedMonthComponents.month {
            return (selectedYear < currentYear) || (selectedYear == currentYear && selectedMonthNum < currentMonthNum)
        }
        return false
    }
}
