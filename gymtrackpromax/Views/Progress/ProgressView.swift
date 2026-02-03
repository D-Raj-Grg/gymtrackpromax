//
//  ProgressView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI
import SwiftData
import Charts

struct ProgressView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<WorkoutSession> { $0.endTime != nil },
        sort: \WorkoutSession.startTime,
        order: .reverse
    )
    private var sessions: [WorkoutSession]

    @Query private var users: [User]

    // MARK: - State

    @State private var viewModel: ProgressViewModel?
    @State private var selectedExercise: ExerciseProgress?
    @State private var showingExerciseChart: Bool = false

    // MARK: - Computed Properties

    private var currentUser: User? {
        users.first
    }

    private var weightUnit: WeightUnit {
        currentUser?.weightUnit ?? .kg
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground
                    .ignoresSafeArea()

                if sessions.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: AppSpacing.section) {
                            // Header
                            headerSection

                            // Time Range Selector
                            timeRangeSelector
                                .padding(.horizontal, AppSpacing.standard)

                            // Summary Stats
                            summaryStatsSection
                                .padding(.horizontal, AppSpacing.standard)

                            // Volume Chart
                            if let vm = viewModel, !vm.volumeData.isEmpty {
                                volumeChartSection
                                    .padding(.horizontal, AppSpacing.standard)
                            }

                            // Muscle Balance
                            if let vm = viewModel, !vm.muscleDistribution.isEmpty {
                                MuscleBalanceView(distribution: vm.muscleDistribution)
                                    .padding(.horizontal, AppSpacing.standard)
                            }

                            // Top Lifts
                            if let vm = viewModel, !vm.topExercises.isEmpty {
                                topLiftsSection
                            }

                            // Personal Records
                            if let vm = viewModel, !vm.personalRecords.isEmpty {
                                personalRecordsSection
                            }

                            Spacer(minLength: AppSpacing.xl)
                        }
                        .padding(.top, AppSpacing.standard)
                    }
                    .refreshable {
                        await loadData()
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showingExerciseChart) {
                if let exercise = selectedExercise {
                    ExerciseChartView(
                        exerciseProgress: exercise,
                        sessions: sessions,
                        weightUnit: weightUnit
                    )
                }
            }
        }
        .onAppear {
            setupViewModel()
        }
        .task {
            await loadData()
        }
        .onChange(of: viewModel?.selectedTimeRange) { _, _ in
            Task {
                await loadData()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Progress")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gymText)

                Text("Track your strength gains")
                    .font(.subheadline)
                    .foregroundStyle(Color.gymTextMuted)
            }

            Spacer()

            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title)
                .foregroundStyle(Color.gymPrimary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, AppSpacing.standard)
    }

    // MARK: - Time Range Selector

    private var timeRangeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.small) {
                ForEach(TimeRange.allCases) { range in
                    timeRangeButton(range)
                }
            }
        }
    }

    private func timeRangeButton(_ range: TimeRange) -> some View {
        let isSelected = viewModel?.selectedTimeRange == range

        return Button {
            HapticManager.buttonTap()
            viewModel?.selectedTimeRange = range
        } label: {
            Text(range.rawValue)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundStyle(isSelected ? Color.gymText : Color.gymTextMuted)
                .padding(.horizontal, AppSpacing.component)
                .padding(.vertical, AppSpacing.small)
                .background(
                    RoundedRectangle(cornerRadius: AppCornerRadius.button)
                        .fill(isSelected ? Color.gymPrimary : Color.gymCard)
                )
        }
        .accessibilityLabel(range.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint("Double tap to show \(range.displayName.lowercased()) data")
    }

    // MARK: - Summary Stats Section

    private var summaryStatsSection: some View {
        HStack(spacing: AppSpacing.component) {
            SummaryStatCard(
                title: "Volume",
                value: viewModel?.formatVolume(viewModel?.totalVolumeInRange ?? 0) ?? "0",
                unit: weightUnit.symbol,
                icon: "scalemass.fill",
                color: Color.gymPrimary
            )

            SummaryStatCard(
                title: "Workouts",
                value: "\(viewModel?.workoutsInRange ?? 0)",
                unit: nil,
                icon: "figure.strengthtraining.traditional",
                color: Color.gymAccent
            )

            SummaryStatCard(
                title: "PRs",
                value: "\(viewModel?.prsInRange ?? 0)",
                unit: nil,
                icon: "trophy.fill",
                color: Color.gymSuccess
            )
        }
    }

    // MARK: - Volume Chart Section

    private var volumeChartSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            Text("Volume Trend")
                .font(.headline)
                .foregroundStyle(Color.gymText)

            VolumeChartView(
                data: viewModel?.volumeData ?? [],
                weightUnit: weightUnit
            )
            .frame(height: 200)
        }
        .padding(AppSpacing.card)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.card)
                .fill(Color.gymCard)
        )
    }

    // MARK: - Top Lifts Section

    private var topLiftsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            HStack {
                Text("Top Lifts")
                    .font(.headline)
                    .foregroundStyle(Color.gymText)

                Spacer()

                Text("by Est. 1RM")
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)
            }
            .padding(.horizontal, AppSpacing.standard)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.component) {
                    ForEach(viewModel?.topExercises ?? []) { exercise in
                        ExerciseProgressCard(
                            exerciseProgress: exercise,
                            weightUnit: weightUnit
                        ) {
                            HapticManager.buttonTap()
                            selectedExercise = exercise
                            showingExerciseChart = true
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.standard)
            }
        }
    }

    // MARK: - Personal Records Section

    private var personalRecordsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            HStack {
                Text("Personal Records")
                    .font(.headline)
                    .foregroundStyle(Color.gymText)

                Spacer()

                Text("\(viewModel?.personalRecords.count ?? 0) PRs")
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)
            }
            .padding(.horizontal, AppSpacing.standard)

            PRListView(
                records: Array((viewModel?.personalRecords ?? []).prefix(10)),
                weightUnit: weightUnit
            )
            .padding(.horizontal, AppSpacing.standard)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack {
            Spacer()

            EmptyStateView.noProgress()
                .padding(.horizontal, AppSpacing.standard)

            Spacer()
        }
    }

    // MARK: - Actions

    private func setupViewModel() {
        if viewModel == nil {
            viewModel = ProgressViewModel(modelContext: modelContext)
        }
    }

    private func loadData() async {
        await viewModel?.loadProgressData(sessions: sessions)
    }
}

// MARK: - Summary Stat Card

private struct SummaryStatCard: View {
    let title: String
    let value: String
    let unit: String?
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gymText)

                if let unit = unit {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(Color.gymTextMuted)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.component)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.card)
                .fill(Color.gymCard)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)\(unit != nil ? " \(unit!)" : "")")
    }
}

// MARK: - Preview

#Preview {
    ProgressView()
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
