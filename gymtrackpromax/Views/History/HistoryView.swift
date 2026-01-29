//
//  HistoryView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI
import SwiftData
import Foundation

/// Main history view showing workout calendar and history list
struct HistoryView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    // MARK: - State

    @State private var viewModel: HistoryViewModel?
    @State private var navigationPath = NavigationPath()

    // MARK: - Computed Properties

    private var currentUser: User? {
        users.first
    }

    private var weightUnit: WeightUnit {
        currentUser?.weightUnit ?? .kg
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color.gymBackground
                    .ignoresSafeArea()

                if let viewModel = viewModel {
                    contentView(viewModel)
                } else {
                    loadingView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("History")
                        .font(.headline)
                        .foregroundStyle(Color.gymText)
                }
            }
            .navigationDestination(for: WorkoutSession.self) { session in
                WorkoutDetailView(
                    session: session,
                    weightUnit: weightUnit,
                    onDelete: {
                        viewModel?.deleteWorkout(session)
                    }
                )
            }
        }
        .onAppear {
            setupViewModel()
        }
        .task {
            await viewModel?.loadSessionsForMonth()
        }
        .onChange(of: viewModel?.selectedMonth) { _, _ in
            Task {
                await viewModel?.loadSessionsForMonth()
            }
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private func contentView(_ viewModel: HistoryViewModel) -> some View {
        ScrollView {
            VStack(spacing: AppSpacing.section) {
                // Month navigation
                monthNavigationHeader(viewModel)

                // Calendar heatmap
                CalendarHeatmapView(
                    month: viewModel.selectedMonth,
                    selectedDate: viewModel.selectedDate,
                    weekStartDay: currentUser?.weekStartDay ?? .systemDefault,
                    intensityForDate: { date in
                        viewModel.workoutIntensity(for: date)
                    },
                    onDateTapped: { date in
                        viewModel.toggleDateSelection(date)
                    }
                )
                .padding(.horizontal, AppSpacing.standard)

                // Filter indicator
                if viewModel.selectedDate != nil {
                    filterIndicator(viewModel)
                }

                // Workouts list
                workoutsSection(viewModel)

                Spacer(minLength: AppSpacing.xl)
            }
            .padding(.top, AppSpacing.standard)
        }
        .refreshable {
            await viewModel.loadSessionsForMonth()
        }
    }

    // MARK: - Month Navigation

    private func monthNavigationHeader(_ viewModel: HistoryViewModel) -> some View {
        HStack {
            // Previous month button
            Button {
                HapticManager.buttonTap()
                viewModel.goToPreviousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.gymPrimary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            // Month/Year display
            Text(viewModel.monthYearDisplay)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.gymText)

            Spacer()

            // Next month button
            Button {
                HapticManager.buttonTap()
                viewModel.goToNextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(viewModel.canGoToNextMonth ? Color.gymPrimary : Color.gymTextMuted.opacity(0.3))
                    .frame(width: 44, height: 44)
            }
            .disabled(!viewModel.canGoToNextMonth)
        }
        .padding(.horizontal, AppSpacing.standard)
    }

    // MARK: - Filter Indicator

    private func filterIndicator(_ viewModel: HistoryViewModel) -> some View {
        HStack {
            Text(filterDateString(viewModel.selectedDate))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.gymText)

            Spacer()

            Button {
                HapticManager.buttonTap()
                viewModel.clearSelection()
            } label: {
                HStack(spacing: 4) {
                    Text("Clear")
                    Image(systemName: "xmark.circle.fill")
                }
                .font(.subheadline)
                .foregroundStyle(Color.gymPrimary)
            }
        }
        .padding(.horizontal, AppSpacing.standard)
        .padding(.vertical, AppSpacing.small)
        .background(Color.gymCard.opacity(0.5))
    }

    // MARK: - Workouts Section

    private func workoutsSection(_ viewModel: HistoryViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            // Section header
            Text(viewModel.selectedDate != nil ? "Workouts" : "Recent Workouts")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.gymText)
                .padding(.horizontal, AppSpacing.standard)

            let sessions = viewModel.filteredSessions()

            if sessions.isEmpty {
                emptyStateView(viewModel)
            } else {
                ForEach(sessions) { session in
                    Button {
                        HapticManager.buttonTap()
                        navigationPath.append(session)
                    } label: {
                        WorkoutHistoryCard(
                            session: session,
                            weightUnit: weightUnit
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, AppSpacing.standard)
                }
            }
        }
    }

    // MARK: - Empty State

    private func emptyStateView(_ viewModel: HistoryViewModel) -> some View {
        Group {
            if viewModel.selectedDate != nil {
                EmptyStateView(
                    icon: "calendar.badge.exclamationmark",
                    title: "No Workouts On This Day",
                    message: "Tap another date or clear the filter to see more workouts.",
                    actionTitle: "Clear Filter",
                    action: { viewModel.clearSelection() }
                )
            } else {
                EmptyStateView(
                    icon: "calendar.badge.exclamationmark",
                    title: "No Workouts This Month",
                    message: "Complete a workout to see it here."
                )
            }
        }
        .padding(.horizontal, AppSpacing.standard)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        LoadingStateView.loadingHistory
    }

    // MARK: - Actions

    private func setupViewModel() {
        if viewModel == nil {
            viewModel = HistoryViewModel(modelContext: modelContext)
        }
    }

    // MARK: - Formatting

    private func filterDateString(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = Foundation.DateFormatter()

        if Calendar.current.isDateInToday(date) {
            return "Today's Workouts"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday's Workouts"
        } else {
            formatter.dateFormat = "EEEE, MMMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Preview

#Preview {
    HistoryView()
        .modelContainer(for: [
            User.self,
            WorkoutSplit.self,
            WorkoutDay.self,
            Exercise.self,
            PlannedExercise.self,
            WorkoutSession.self,
            ExerciseLog.self,
            SetLog.self
        ], inMemory: true)
}
