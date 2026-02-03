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

    // Search & Filter
    var searchText: String = ""
    var selectedMuscleFilter: MuscleGroup? = nil

    // Pagination
    var displayedSessions: [WorkoutSession] = []
    var hasMoreData: Bool = false
    private var currentPage: Int = 0
    private let pageSize: Int = 20

    // PR detection
    var sessionsWithPRs: Set<UUID> = []

    // Cached data
    private var cachedSessions: [WorkoutSession] = []
    private var maxMonthlyVolume: Double = 0

    // Static PR cache (shared across instances, only recomputed when sessions change)
    private static var cachedPRSessionIds: Set<UUID> = []
    private static var cachedPRSessionCount: Int = 0

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
            detectSessionPRs()
            resetPagination()
        } catch {
            print("Error fetching sessions for month: \(error)")
            cachedSessions = []
        }
    }

    /// Detect which sessions contain PRs (uses static cache to avoid rescanning on month navigation)
    private func detectSessionPRs() {
        // Fetch all completed sessions chronologically
        let allPredicate = #Predicate<WorkoutSession> { session in
            session.endTime != nil
        }
        let allDescriptor = FetchDescriptor<WorkoutSession>(
            predicate: allPredicate,
            sortBy: [SortDescriptor(\.startTime)]
        )

        guard let allSessions = try? modelContext.fetch(allDescriptor) else { return }

        // Only recompute if session count changed (new sessions added/deleted)
        if allSessions.count != Self.cachedPRSessionCount {
            Self.cachedPRSessionIds.removeAll()
            Self.cachedPRSessionCount = allSessions.count

            var exerciseBests: [UUID: Double] = [:]

            for session in allSessions {
                for log in session.exerciseLogs {
                    guard let exercise = log.exercise else { continue }

                    for set in log.workingSetsArray {
                        let currentBest = exerciseBests[exercise.id] ?? 0
                        if set.estimated1RM > currentBest {
                            exerciseBests[exercise.id] = set.estimated1RM
                            Self.cachedPRSessionIds.insert(session.id)
                        }
                    }
                }
            }
        }

        sessionsWithPRs = Self.cachedPRSessionIds
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

    // MARK: - Pagination

    private func resetPagination() {
        currentPage = 0
        let allFiltered = applyFilters(cachedSessions.filter { $0.isCompleted })
        displayedSessions = Array(allFiltered.prefix(pageSize))
        hasMoreData = allFiltered.count > pageSize
    }

    /// Load more sessions for infinite scroll
    func loadMoreSessions() {
        guard hasMoreData, selectedDate == nil else { return }

        currentPage += 1
        let allFiltered = applyFilters(cachedSessions.filter { $0.isCompleted })
        let startIndex = currentPage * pageSize
        guard startIndex < allFiltered.count else {
            hasMoreData = false
            return
        }
        let endIndex = min(startIndex + pageSize, allFiltered.count)
        displayedSessions.append(contentsOf: allFiltered[startIndex..<endIndex])
        hasMoreData = endIndex < allFiltered.count
    }

    // MARK: - Search & Filter

    /// Apply search and muscle filter to sessions
    private func applyFilters(_ sessions: [WorkoutSession]) -> [WorkoutSession] {
        var result = sessions

        // Text search
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { session in
                session.exerciseLogs.contains { log in
                    log.exerciseName.lowercased().contains(query)
                }
            }
        }

        // Muscle group filter
        if let muscle = selectedMuscleFilter {
            result = result.filter { session in
                session.exerciseLogs.contains { log in
                    log.exercise?.primaryMuscle == muscle
                }
            }
        }

        return result
    }

    /// Get filtered sessions based on search, filter, and date selection
    func filteredSessions() -> [WorkoutSession] {
        if let selectedDate = selectedDate {
            let dayFiltered = workoutsForDate(selectedDate)
            return applyFilters(dayFiltered)
        }

        // When using search/filter, re-apply to all cached
        if !searchText.isEmpty || selectedMuscleFilter != nil {
            return applyFilters(cachedSessions.filter { $0.isCompleted })
        }

        return displayedSessions
    }

    /// Called when search text or filter changes
    func onFilterChanged() {
        resetPagination()
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

    /// Calculate workout intensity for a specific date (0-1 scale)
    func workoutIntensity(for date: Date) -> Double {
        guard maxMonthlyVolume > 0 else { return 0 }

        let sessions = workoutsForDate(date)
        guard !sessions.isEmpty else { return 0 }

        let totalVolume = sessions.reduce(0) { $0 + $1.totalVolume }

        // Return intensity between 0.3 and 1.0 for any workout day
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
            cachedSessions.removeAll { $0.id == session.id }
            displayedSessions.removeAll { $0.id == session.id }
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
            selectedDate = nil
        } else {
            selectedDate = dayStart
        }
    }

    /// Clear date selection
    func clearSelection() {
        selectedDate = nil
    }

    /// Clear muscle filter
    func clearMuscleFilter() {
        selectedMuscleFilter = nil
        onFilterChanged()
    }

    // MARK: - Formatting

    /// Format the month/year display
    var monthYearDisplay: String {
        let formatter = Foundation.DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    /// Check if can navigate to next month
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
