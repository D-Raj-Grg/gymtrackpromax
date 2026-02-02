//
//  WorkoutTabView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI
import SwiftData

struct WorkoutTabView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    // MARK: - State

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

    private var sortedWorkoutDays: [WorkoutDay] {
        guard let days = activeSplit?.workoutDays else { return [] }
        let startIndex = (currentUser?.weekStartDay ?? .monday).firstWeekdayIndex

        return days.sorted { a, b in
            let dayA = a.scheduledWeekdays.sorted().first ?? Int.max
            let dayB = b.scheduledWeekdays.sorted().first ?? Int.max

            let normalizedA = (dayA - startIndex + 7) % 7
            let normalizedB = (dayB - startIndex + 7) % 7
            return normalizedA < normalizedB
        }
    }

    private var isRestDay: Bool {
        activeSplit?.isRestDay ?? true
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.gymBackground
                    .ignoresSafeArea()

                if activeSplit != nil {
                    workoutContent
                } else {
                    noSplitContent
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
    }

    // MARK: - Workout Content

    private var workoutContent: some View {
        ScrollView {
            VStack(spacing: AppSpacing.section) {
                // Header
                headerSection

                // Today's workout (prominent)
                todaySection
                    .padding(.horizontal, AppSpacing.standard)

                // Weekly schedule
                weeklyScheduleSection
                    .padding(.horizontal, AppSpacing.standard)

                Spacer(minLength: AppSpacing.xl)
            }
            .padding(.top, AppSpacing.standard)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Workouts")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gymText)

                if let split = activeSplit {
                    Text(split.name)
                        .font(.subheadline)
                        .foregroundStyle(Color.gymTextMuted)
                }
            }

            Spacer()

            Button {
                showingSplitList = true
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "pencil.circle")
                        .font(.title3)
                    Text("Edit")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(Color.gymPrimary)
            }
        }
        .padding(.horizontal, AppSpacing.standard)
    }

    // MARK: - Today Section

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            Text("Today")
                .font(.headline)
                .foregroundStyle(Color.gymTextMuted)

            if let workout = todaysWorkout {
                todayWorkoutCard(workout)
            } else {
                restDayCard
            }
        }
    }

    private func todayWorkoutCard(_ workout: WorkoutDay) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.standard) {
            // Workout name with badge
            HStack {
                Text(workout.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gymText)

                Spacer()

                Text(workout.inProgressSession != nil ? "In Progress" : "Scheduled")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.gymText)
                    .padding(.horizontal, AppSpacing.component)
                    .padding(.vertical, AppSpacing.xs)
                    .background(workout.inProgressSession != nil ? Color.gymWarning : Color.gymPrimary)
                    .clipShape(Capsule())
            }

            // Muscle group chips
            if !workout.primaryMuscles.isEmpty {
                muscleChips(workout.primaryMuscles)
            }

            // Stats row
            HStack(spacing: AppSpacing.section) {
                statItem(
                    icon: "dumbbell.fill",
                    value: "\(workout.exerciseCount)",
                    label: "exercises"
                )

                statItem(
                    icon: "clock.fill",
                    value: "~\(workout.estimatedDuration)",
                    label: "min"
                )

                statItem(
                    icon: "flame.fill",
                    value: "\(workout.totalSets)",
                    label: "sets"
                )
            }

            // In-progress indicator
            if let session = workout.inProgressSession {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "pause.circle.fill")
                        .foregroundStyle(Color.gymWarning)

                    Text("In Progress")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.gymWarning)

                    Text("•")
                        .foregroundStyle(Color.gymTextMuted)

                    Text("\(session.exerciseLogs.flatMap(\.sets).count) sets logged")
                        .font(.caption)
                        .foregroundStyle(Color.gymTextMuted)

                    Spacer()
                }
            }

            // Start workout or add exercises button
            if workout.exerciseCount > 0 {
                let isInProgress = workout.inProgressSession != nil

                Button {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    selectedWorkoutDay = workout
                } label: {
                    HStack {
                        Image(systemName: isInProgress ? "play.circle.fill" : "play.fill")
                        Text(isInProgress ? "Resume Workout" : "Start Workout")
                    }
                }
                .primaryButtonStyle()
                .padding(.top, AppSpacing.small)
            } else {
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    showingSplitList = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Exercises")
                    }
                }
                .secondaryButtonStyle()
                .padding(.top, AppSpacing.small)
            }
        }
        .padding(AppSpacing.card)
        .background(Color.gymCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.cardLarge))
    }

    private var restDayCard: some View {
        VStack(spacing: AppSpacing.standard) {
            Image(systemName: "bed.double.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.gymSuccess)

            Text("Rest Day")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.gymText)

            Text("Recovery is just as important as training. Take it easy today!")
                .font(.subheadline)
                .foregroundStyle(Color.gymTextMuted)
                .multilineTextAlignment(.center)

            // Option to start any workout
            Button {
                // Show first workout as option
                if let firstWorkout = sortedWorkoutDays.first {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    selectedWorkoutDay = firstWorkout
                }
            } label: {
                Text("Start a Workout Anyway")
            }
            .secondaryButtonStyle()
            .padding(.top, AppSpacing.small)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.card)
        .background(Color.gymCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.cardLarge))
    }

    // MARK: - Weekly Schedule Section

    private var weeklyScheduleSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.component) {
            Text("This Week")
                .font(.headline)
                .foregroundStyle(Color.gymTextMuted)

            VStack(spacing: AppSpacing.component) {
                ForEach(sortedWorkoutDays, id: \.id) { workoutDay in
                    workoutDayRow(workoutDay)
                }
            }
        }
    }

    private func workoutDayRow(_ workoutDay: WorkoutDay) -> some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            if workoutDay.exerciseCount > 0 {
                selectedWorkoutDay = workoutDay
            } else {
                showingSplitList = true
            }
        } label: {
            HStack(spacing: AppSpacing.component) {
                // Workout icon
                ZStack {
                    Circle()
                        .fill(workoutDay.inProgressSession != nil ? Color.gymWarning : (isToday(workoutDay) ? Color.gymPrimary : Color.gymCardHover))
                        .frame(width: 44, height: 44)

                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.headline)
                        .foregroundStyle(workoutDay.inProgressSession != nil ? Color.gymText : (isToday(workoutDay) ? Color.gymText : Color.gymTextMuted))
                }

                // Workout info
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(workoutDay.name)
                        .font(.headline)
                        .foregroundStyle(Color.gymText)

                    HStack(spacing: AppSpacing.small) {
                        Text("\(workoutDay.exerciseCount) exercises")
                            .font(.caption)
                            .foregroundStyle(Color.gymTextMuted)

                        if !workoutDay.scheduledWeekdays.isEmpty {
                            Text("•")
                                .foregroundStyle(Color.gymTextMuted)

                            Text(workoutDay.scheduledDaysDisplay)
                                .font(.caption)
                                .foregroundStyle(Color.gymTextMuted)
                        }
                    }
                }

                Spacer()

                // In-progress badge
                if workoutDay.inProgressSession != nil {
                    Text("In Progress")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.gymText)
                        .padding(.horizontal, AppSpacing.small)
                        .padding(.vertical, 2)
                        .background(Color.gymWarning)
                        .clipShape(Capsule())
                }

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)
            }
            .padding(AppSpacing.standard)
            .background(Color.gymCard)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
        }
        .buttonStyle(.plain)
    }

    // MARK: - No Split Content

    private var noSplitContent: some View {
        VStack(spacing: AppSpacing.section) {
            Spacer()

            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(Color.gymTextMuted)

            Text("No Workout Plan")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.gymText)

            Text("Create a workout split to get started with your training schedule.")
                .font(.subheadline)
                .foregroundStyle(Color.gymTextMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.large)

            Spacer()
        }
    }

    // MARK: - Subviews

    private func muscleChips(_ muscles: [MuscleGroup]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.small) {
                ForEach(muscles, id: \.self) { muscle in
                    Text(muscle.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.gymText)
                        .padding(.horizontal, AppSpacing.component)
                        .padding(.vertical, AppSpacing.xs)
                        .background(Color.gymCardHover)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.gymPrimary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.gymText)

            Text(label)
                .font(.caption)
                .foregroundStyle(Color.gymTextMuted)
        }
    }

    // MARK: - Helpers

    private func isToday(_ workoutDay: WorkoutDay) -> Bool {
        todaysWorkout?.id == workoutDay.id
    }
}

// MARK: - Preview

#Preview("With Split") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: User.self, WorkoutSplit.self, WorkoutDay.self, Exercise.self,
        PlannedExercise.self, WorkoutSession.self, ExerciseLog.self, SetLog.self,
        configurations: config
    )

    // Create user with split
    let user = User(name: "Test User")
    container.mainContext.insert(user)

    let split = WorkoutSplit(name: "Push Pull Legs", splitType: .ppl, isActive: true)
    split.user = user

    let pushDay = WorkoutDay(name: "Push Day", dayOrder: 0, scheduledWeekdays: [1, 4])
    let pullDay = WorkoutDay(name: "Pull Day", dayOrder: 1, scheduledWeekdays: [2, 5])
    let legDay = WorkoutDay(name: "Leg Day", dayOrder: 2, scheduledWeekdays: [3, 6])

    pushDay.split = split
    pullDay.split = split
    legDay.split = split

    return WorkoutTabView()
        .modelContainer(container)
}

#Preview("No Split") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: User.self, WorkoutSplit.self, WorkoutDay.self, Exercise.self,
        PlannedExercise.self, WorkoutSession.self, ExerciseLog.self, SetLog.self,
        configurations: config
    )

    let user = User(name: "Test User")
    container.mainContext.insert(user)

    return WorkoutTabView()
        .modelContainer(container)
}
