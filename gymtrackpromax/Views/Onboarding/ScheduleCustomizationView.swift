//
//  ScheduleCustomizationView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

/// Step 4: Customize workout schedule
struct ScheduleCustomizationView: View {
    @Bindable var viewModel: OnboardingViewModel

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header with back button and progress
            header

            ScrollView {
                VStack(spacing: AppSpacing.section) {
                    // Title
                    titleSection

                    // Day selector
                    daySelector

                    // Schedule summary
                    scheduleSummary

                    // Workout assignments
                    workoutAssignments
                }
                .padding(.horizontal, AppSpacing.standard)
                .padding(.top, AppSpacing.standard)
                .padding(.bottom, AppSpacing.section)
            }

            // Continue button
            continueButton
        }
        .onAppear {
            // Ensure default weekdays are set based on split
            if viewModel.selectedWeekdays.isEmpty {
                viewModel.setDefaultWeekdays()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                viewModel.goBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.gymText)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            OnboardingProgressBar(
                currentStep: 4,
                totalSteps: OnboardingStep.totalSteps
            )

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, AppSpacing.small)
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(spacing: AppSpacing.small) {
            Text("Set your schedule")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(Color.gymText)

            Text("Pick the days you want to train")
                .font(.body)
                .foregroundStyle(Color.gymTextMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Day Selector

    /// Weekdays ordered based on user's week start day preference
    private var orderedWeekdays: [Weekday] {
        viewModel.weekStartDay.orderedWeekdays
    }

    private var daySelector: some View {
        VStack(spacing: AppSpacing.component) {
            // Day toggle buttons
            HStack(spacing: AppSpacing.small) {
                ForEach(orderedWeekdays, id: \.rawValue) { weekday in
                    DayToggleButton(
                        dayLetter: weekday.letter,
                        isSelected: viewModel.selectedWeekdays.contains(weekday.rawValue),
                        onTap: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.easeInOut(duration: AppAnimation.quick)) {
                                viewModel.toggleWeekday(weekday.rawValue)
                            }
                        }
                    )
                }
            }

            // Days count indicator
            HStack(spacing: AppSpacing.xs) {
                Text("\(viewModel.selectedDaysCount)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(dayCountColor)

                Text("of \(viewModel.requiredDays) days selected")
                    .font(.subheadline)
                    .foregroundStyle(Color.gymTextMuted)
            }
        }
        .padding(AppSpacing.standard)
        .background(Color.gymCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
    }

    private var dayCountColor: Color {
        if viewModel.selectedDaysCount < viewModel.requiredDays {
            return .gymWarning
        } else if viewModel.selectedDaysCount == viewModel.requiredDays {
            return .gymSuccess
        } else {
            return .gymPrimary
        }
    }

    // MARK: - Schedule Summary

    private var scheduleSummary: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Your Schedule")
                .font(.headline)
                .foregroundStyle(Color.gymText)

            Text("\(viewModel.selectedSplit.displayName) • \(viewModel.selectedDaysCount) days per week")
                .font(.subheadline)
                .foregroundStyle(Color.gymTextMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Workout Assignments

    /// Get ordered weekday assignments based on system locale preference
    private var orderedWeekdayAssignments: [(weekday: Int, workoutName: String?)] {
        let assignments = viewModel.weekdayAssignments
        return orderedWeekdays.compactMap { weekday in
            assignments.first { $0.weekday == weekday.rawValue }
        }
    }

    private var workoutAssignments: some View {
        VStack(spacing: AppSpacing.small) {
            ForEach(orderedWeekdayAssignments, id: \.weekday) { assignment in
                WorkoutAssignmentRow(
                    weekday: Weekday(rawValue: assignment.weekday) ?? .sunday,
                    workoutName: assignment.workoutName
                )
            }
            .onMove { source, destination in
                viewModel.reorderWorkoutAssignments(from: source, to: destination)
            }
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        VStack(spacing: AppSpacing.small) {
            if viewModel.selectedDaysCount < viewModel.requiredDays {
                Text("Select at least \(viewModel.requiredDays) days to continue")
                    .font(.caption)
                    .foregroundStyle(Color.gymWarning)
            }

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                viewModel.goToNext()
            } label: {
                Text("Continue")
            }
            .primaryButtonStyle(isEnabled: viewModel.isScheduleValid)
            .disabled(!viewModel.isScheduleValid)
        }
        .padding(.horizontal, AppSpacing.standard)
        .padding(.vertical, AppSpacing.standard)
        .background(Color.gymBackground)
    }
}

// MARK: - Workout Assignment Row

private struct WorkoutAssignmentRow: View {
    let weekday: Weekday
    let workoutName: String?

    var body: some View {
        HStack {
            // Weekday name
            Text(weekday.fullName)
                .font(.subheadline)
                .foregroundStyle(workoutName != nil ? Color.gymText : Color.gymTextMuted)
                .frame(width: 100, alignment: .leading)

            Spacer()

            // Workout or rest
            if let workout = workoutName {
                Text(workout)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.gymPrimary)
                    .padding(.horizontal, AppSpacing.component)
                    .padding(.vertical, AppSpacing.xs)
                    .background(Color.gymPrimary.opacity(0.15))
                    .clipShape(Capsule())
            } else {
                Text("Rest")
                    .font(.subheadline)
                    .foregroundStyle(Color.gymTextMuted)
                    .padding(.horizontal, AppSpacing.component)
                    .padding(.vertical, AppSpacing.xs)
                    .background(Color.gymCardHover)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, AppSpacing.standard)
        .padding(.vertical, AppSpacing.component)
        .background(Color.gymCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.small))
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gymBackground.ignoresSafeArea()
        ScheduleCustomizationView(viewModel: {
            let vm = OnboardingViewModel()
            vm.selectedSplit = .ppl
            vm.setDefaultWeekdays()
            return vm
        }())
    }
    .preferredColorScheme(.dark)
}
