//
//  DashboardView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI
import SwiftData
import Foundation

struct DashboardView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    // MARK: - State

    @State private var viewModel: DashboardViewModel?
    @State private var selectedWorkoutDay: WorkoutDay?
    @State private var showingSplitList: Bool = false

    // MARK: - Computed Properties

    private var currentUser: User? {
        users.first
    }

    private var activeSplit: WorkoutSplit? {
        currentUser?.activeSplit
    }

    private var todaysWorkout: WorkoutDay? {
        activeSplit?.todaysWorkout
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.section) {
                        // Header
                        headerSection

                        // Streak card
                        StreakCard(streakCount: currentUser?.currentStreak ?? 0)
                            .padding(.horizontal, AppSpacing.standard)

                        // Today's workout card
                        TodayWorkoutCard(
                            workoutDay: todaysWorkout,
                            onStartWorkout: { startWorkout() },
                            onAddExercises: { showingSplitList = true }
                        )
                        .padding(.horizontal, AppSpacing.standard)

                        // Quick stats
                        QuickStatsView(
                            workoutsThisWeek: viewModel?.workoutsThisWeek ?? 0,
                            volumeThisWeek: viewModel?.volumeDisplayString ?? "0",
                            prsThisWeek: viewModel?.prsThisWeek ?? 0,
                            weightUnit: currentUser?.weightUnit ?? .kg
                        )
                        .padding(.horizontal, AppSpacing.standard)

                        Spacer(minLength: AppSpacing.xl)
                    }
                    .padding(.top, AppSpacing.standard)
                }
                .refreshable {
                    await refreshData()
                }
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(item: $selectedWorkoutDay) { day in
            ActiveWorkoutView(workoutDay: day)
        }
        .sheet(isPresented: $showingSplitList) {
            NavigationStack {
                SplitListView()
            }
        }
        .onAppear {
            setupViewModel()
        }
        .task {
            await viewModel?.loadWeeklyStats()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(greetingText)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gymText)

                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(Color.gymTextMuted)
            }

            Spacer()

            // Profile avatar button
            NavigationLink {
                ProfileView()
            } label: {
                profileAvatar
            }
        }
        .padding(.horizontal, AppSpacing.standard)
    }

    private var greetingText: String {
        if let name = currentUser?.name {
            let hour = Calendar.current.component(.hour, from: Date())
            let greeting: String
            switch hour {
            case 0..<12:
                greeting = "Good morning"
            case 12..<17:
                greeting = "Good afternoon"
            default:
                greeting = "Good evening"
            }
            return "\(greeting), \(name)!"
        }
        return "Welcome!"
    }

    private var formattedDate: String {
        let formatter = Foundation.DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    private var profileAvatar: some View {
        ZStack {
            if let imageData = currentUser?.profileImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gymPrimary)
                    .frame(width: 44, height: 44)

                if let name = currentUser?.name, let initial = name.first {
                    Text(String(initial).uppercased())
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.white)
                } else {
                    Image(systemName: "person.fill")
                        .font(.headline)
                        .foregroundStyle(Color.white)
                }
            }
        }
    }

    // MARK: - Actions

    private func setupViewModel() {
        if viewModel == nil {
            viewModel = DashboardViewModel(modelContext: modelContext)
        }
    }

    private func refreshData() async {
        await viewModel?.loadWeeklyStats()
    }

    private func startWorkout() {
        guard let workout = todaysWorkout else { return }
        HapticManager.mediumImpact()
        selectedWorkoutDay = workout
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
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
