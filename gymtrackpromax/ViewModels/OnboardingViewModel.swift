//
//  OnboardingViewModel.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import Foundation
import SwiftData
import SwiftUI
import WidgetKit

/// ViewModel managing all onboarding state and logic
@Observable
@MainActor
final class OnboardingViewModel {
    // MARK: - User Input State

    var userName: String = ""
    var weightUnit: WeightUnit = .kg
    var weekStartDay: WeekStartDay = .monday
    var experienceLevel: ExperienceLevel = .beginner
    var fitnessGoal: FitnessGoal = .buildMuscle
    var selectedSplit: SplitType = .fullBody
    var selectedWeekdays: Set<Int> = [1, 2, 3, 4, 5] // Mon-Fri default (0=Sun, 1=Mon, ..., 6=Sat)

    // MARK: - Navigation State

    var currentStep: OnboardingStep = .splash
    var isNavigating: Bool = false

    // MARK: - Validation

    /// Whether user info step is valid
    var isUserInfoValid: Bool {
        !userName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Whether schedule selection is valid
    var isScheduleValid: Bool {
        selectedWeekdays.count >= selectedSplit.daysPerWeek
    }

    /// Number of days selected
    var selectedDaysCount: Int {
        selectedWeekdays.count
    }

    /// Required days for selected split
    var requiredDays: Int {
        selectedSplit.daysPerWeek
    }

    // MARK: - Computed Properties

    /// Weekday assignments based on selected days and split
    var weekdayAssignments: [(weekday: Int, workoutName: String?)] {
        let sortedWeekdays = selectedWeekdays.sorted()
        let dayNames = selectedSplit.defaultDayNames

        var assignments: [(Int, String?)] = []

        for weekday in 0..<7 {
            if let index = sortedWeekdays.firstIndex(of: weekday), index < dayNames.count {
                assignments.append((weekday, dayNames[index]))
            } else {
                assignments.append((weekday, nil))
            }
        }

        return assignments
    }

    /// Summary text for selected workout days
    var workoutDaysSummary: String {
        "\(selectedDaysCount) days per week"
    }

    /// Start date formatted
    var startDateFormatted: String {
        Date().formatted(date: .abbreviated, time: .omitted)
    }

    // MARK: - Navigation Helpers

    /// Navigate to next step
    func goToNext() {
        guard let nextStep = currentStep.next else { return }
        withAnimation {
            currentStep = nextStep
        }
    }

    /// Navigate to previous step
    func goBack() {
        guard let previousStep = currentStep.previous else { return }
        withAnimation {
            currentStep = previousStep
        }
    }

    /// Skip to specific step
    func skipTo(_ step: OnboardingStep) {
        withAnimation {
            currentStep = step
        }
    }

    // MARK: - Schedule Logic

    /// Toggle a weekday selection
    func toggleWeekday(_ weekday: Int) {
        if selectedWeekdays.contains(weekday) {
            selectedWeekdays.remove(weekday)
        } else {
            selectedWeekdays.insert(weekday)
        }
    }

    /// Set default weekdays based on split type and week start preference
    func setDefaultWeekdays() {
        selectedWeekdays.removeAll()

        // Get the first day index based on user's week start preference
        let firstDayIndex = weekStartDay.firstWeekdayIndex  // Sunday=0, Monday=1

        // Define patterns as offsets from week start (0 = first day of week)
        let offsets: [Int]

        switch selectedSplit {
        case .ppl, .arnoldSplit:
            // 6 consecutive days from week start
            offsets = [0, 1, 2, 3, 4, 5]
        case .broSplit:
            // 5 consecutive days from week start
            offsets = [0, 1, 2, 3, 4]
        case .ulPpl:
            // 5 days with day 2 as rest (e.g., Sun, Mon, Wed, Thu, Fri for Sunday start)
            offsets = [0, 1, 3, 4, 5]
        case .pplUl:
            // 5 days with day 3 as rest (e.g., Sun, Mon, Tue, Thu, Fri for Sunday start)
            offsets = [0, 1, 2, 4, 5]
        case .upperLower:
            // 4 days: days 0, 1, 3, 4
            offsets = [0, 1, 3, 4]
        case .fullBody:
            // 3 days: every other day (days 0, 2, 4)
            offsets = [0, 2, 4]
        case .custom:
            // 5 consecutive days
            offsets = [0, 1, 2, 3, 4]
        }

        // Convert offsets to actual weekday indices (0-6 where 0=Sunday)
        selectedWeekdays = Set(offsets.map { (firstDayIndex + $0) % 7 })
    }

    /// Get recommended split based on experience level
    func recommendedSplit(for level: ExperienceLevel) -> SplitType {
        switch level {
        case .beginner:
            return .fullBody
        case .intermediate:
            return .ppl
        case .advanced:
            return .arnoldSplit
        }
    }

    // MARK: - Complete Onboarding

    /// Complete onboarding and save all data
    func completeOnboarding(context: ModelContext) async throws {
        // Create user
        let user = User(
            name: userName.trimmingCharacters(in: .whitespaces),
            weightUnit: weightUnit,
            weekStartDay: weekStartDay,
            experienceLevel: experienceLevel,
            fitnessGoal: fitnessGoal
        )
        context.insert(user)

        // Generate workout split using SplitTemplateService
        let splitService = SplitTemplateService.shared
        let workoutSplit = try await splitService.generateSplit(
            type: selectedSplit,
            selectedWeekdays: Array(selectedWeekdays).sorted(),
            fitnessGoal: fitnessGoal,
            context: context
        )

        // Associate split with user
        workoutSplit.user = user
        user.workoutSplits.append(workoutSplit)

        // Save context
        try context.save()

        // Mark onboarding complete
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.hasCompletedOnboarding)

        // Refresh widgets so they pick up the new split data
        WidgetUpdateService.reloadAllTimelines()
    }
}

// MARK: - Onboarding Step Enum

/// Steps in the onboarding flow
enum OnboardingStep: Int, CaseIterable {
    case splash = 0
    case welcome = 1
    case userInfo = 2
    case goalSelection = 3
    case splitSelection = 4
    case scheduleCustomization = 5
    case complete = 6

    /// Next step in the flow
    var next: OnboardingStep? {
        OnboardingStep(rawValue: rawValue + 1)
    }

    /// Previous step in the flow
    var previous: OnboardingStep? {
        OnboardingStep(rawValue: rawValue - 1)
    }

    /// Step number for progress indicator (1-4 for data collection steps)
    var stepNumber: Int? {
        switch self {
        case .userInfo: return 1
        case .goalSelection: return 2
        case .splitSelection: return 3
        case .scheduleCustomization: return 4
        default: return nil
        }
    }

    /// Whether this step shows progress indicator
    var showsProgress: Bool {
        stepNumber != nil
    }

    /// Total number of numbered steps
    static let totalSteps = 4
}

// MARK: - WithAnimation Helper

private func withAnimation(_ body: () -> Void) {
    SwiftUI.withAnimation(.easeInOut(duration: AppAnimation.standard)) {
        body()
    }
}
