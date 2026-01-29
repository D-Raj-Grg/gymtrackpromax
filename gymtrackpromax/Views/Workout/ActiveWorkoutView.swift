//
//  ActiveWorkoutView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var users: [User]

    // MARK: - Properties

    let workoutDay: WorkoutDay

    // MARK: - State

    @State private var viewModel: WorkoutViewModel?
    @State private var workoutNotes: String = ""

    // MARK: - Computed

    private var currentUser: User? {
        users.first
    }

    private var weightUnit: WeightUnit {
        currentUser?.weightUnit ?? .kg
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.gymBackground
                .ignoresSafeArea()

            if let vm = viewModel {
                if vm.isWorkoutCompleted {
                    // Show summary
                    WorkoutSummaryView(
                        session: vm.currentSession!,
                        achievedPRs: vm.achievedPRs,
                        notes: $workoutNotes,
                        weightUnit: weightUnit,
                        onSave: {
                            // Notes are already saved by completeWorkout
                            dismiss()
                        }
                    )
                } else {
                    // Active workout content
                    VStack(spacing: 0) {
                        // Header
                        workoutHeader(vm)

                        // Exercise content
                        if let exerciseLog = vm.currentExerciseLog {
                            ExerciseLogView(
                                exerciseLog: exerciseLog,
                                plannedExercise: vm.currentPlannedExercise,
                                previousPerformance: vm.previousPerformanceDisplay,
                                achievedPRs: vm.achievedPRs,
                                weightUnit: weightUnit,
                                pendingWeight: Binding(
                                    get: { vm.pendingWeight },
                                    set: { vm.pendingWeight = $0 }
                                ),
                                pendingReps: Binding(
                                    get: { vm.pendingReps },
                                    set: { vm.pendingReps = $0 }
                                ),
                                pendingDuration: Binding(
                                    get: { vm.pendingDuration },
                                    set: { vm.pendingDuration = $0 }
                                ),
                                pendingRPE: Binding(
                                    get: { vm.pendingRPE },
                                    set: { vm.pendingRPE = $0 }
                                ),
                                isWarmup: Binding(
                                    get: { vm.isWarmupSet },
                                    set: { vm.isWarmupSet = $0 }
                                ),
                                isDropset: Binding(
                                    get: { vm.isDropset },
                                    set: { vm.isDropset = $0 }
                                ),
                                canDuplicateLastSet: vm.canDuplicateLastSet,
                                onLogSet: { vm.logSet() },
                                onDuplicateLastSet: { vm.duplicateLastSet() },
                                onDeleteSet: { vm.deleteSet($0) },
                                onEditSet: { vm.editSet($0) },
                                onIncrementWeight: { vm.incrementWeight() },
                                onDecrementWeight: { vm.decrementWeight() },
                                onIncrementReps: { vm.incrementReps() },
                                onDecrementReps: { vm.decrementReps() },
                                onNotesChanged: { vm.updateExerciseNotes($0) }
                            )
                        }

                        // Bottom bar
                        bottomBar(vm)
                    }

                    // Rest timer overlay
                    if vm.showRestTimerOverlay {
                        RestTimerOverlay(
                            timerService: vm.timerService,
                            nextExercise: vm.nextPlannedExercise,
                            onDismiss: { vm.dismissRestTimerOverlay() }
                        )
                        .transition(.opacity)
                        .zIndex(100)
                    }
                }
            } else {
                // Loading state
                LoadingStateView(message: "Starting workout...")
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupViewModel()
        }
        .sheet(isPresented: Binding(
            get: { viewModel?.showExerciseListSheet ?? false },
            set: { viewModel?.showExerciseListSheet = $0 }
        )) {
            if let vm = viewModel {
                ExerciseListSheet(
                    exerciseLogs: vm.exerciseLogs,
                    currentIndex: vm.currentExerciseIndex,
                    onSelectExercise: { vm.goToExercise(at: $0) },
                    onDismiss: { vm.showExerciseListSheet = false }
                )
            }
        }
        .confirmationDialog(
            "End Workout?",
            isPresented: Binding(
                get: { viewModel?.showAbandonConfirmation ?? false },
                set: { viewModel?.showAbandonConfirmation = $0 }
            ),
            titleVisibility: .visible
        ) {
            Button("Save Progress", role: .none) {
                viewModel?.abandonWorkout(saveProgress: true)
                dismiss()
            }

            Button("Discard Workout", role: .destructive) {
                viewModel?.abandonWorkout(saveProgress: false)
                dismiss()
            }

            Button("Continue Workout", role: .cancel) {}
        } message: {
            Text("What would you like to do with your current progress?")
        }
    }

    // MARK: - Header

    private func workoutHeader(_ vm: WorkoutViewModel) -> some View {
        HStack(spacing: AppSpacing.component) {
            // Close button
            Button {
                HapticManager.buttonTap()
                vm.showAbandonConfirmation = true
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(Color.gymText)
                    .frame(width: 36, height: 36)
                    .background(Color.gymCard)
                    .clipShape(Circle())
            }
            .accessibleButton(label: "End workout", hint: "Double tap to show options for ending this workout")

            // Workout name
            VStack(alignment: .leading, spacing: 2) {
                Text(workoutDay.name)
                    .font(.headline)
                    .foregroundStyle(Color.gymText)
                    .lineLimit(1)

                // Progress indicator
                Text("\(vm.currentExerciseIndex + 1)/\(vm.exerciseLogs.count) exercises")
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(workoutDay.name). Exercise \(vm.currentExerciseIndex + 1) of \(vm.exerciseLogs.count)")

            Spacer()

            // Timer
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundStyle(Color.gymTextMuted)

                Text(vm.elapsedTimeDisplay)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(Color.gymText)
            }
            .padding(.horizontal, AppSpacing.component)
            .padding(.vertical, AppSpacing.small)
            .background(Color.gymCard)
            .clipShape(Capsule())
            .accessibilityLabel("Workout duration: \(vm.elapsedTimeDisplay)")

            // Exercise list button
            Button {
                HapticManager.buttonTap()
                vm.showExerciseListSheet = true
            } label: {
                Image(systemName: "list.bullet")
                    .font(.headline)
                    .foregroundStyle(Color.gymText)
                    .frame(width: 36, height: 36)
                    .background(Color.gymCard)
                    .clipShape(Circle())
            }
            .accessibleButton(label: "Exercise list", hint: "Double tap to view all exercises in this workout")
        }
        .padding(.horizontal, AppSpacing.standard)
        .padding(.vertical, AppSpacing.component)
        .background(Color.gymBackground)
    }

    // MARK: - Bottom Bar

    private func bottomBar(_ vm: WorkoutViewModel) -> some View {
        VStack(spacing: AppSpacing.component) {
            // Next exercise preview (if not on last)
            if !vm.isOnLastExercise {
                NextExercisePreview(exercise: vm.nextPlannedExercise)
                    .padding(.horizontal, AppSpacing.standard)
            }

            // Navigation buttons
            HStack(spacing: AppSpacing.component) {
                // Previous exercise
                if vm.hasPreviousExercise {
                    Button {
                        vm.previousExercise()
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Previous")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.gymText)
                        .padding(.horizontal, AppSpacing.standard)
                        .padding(.vertical, AppSpacing.component)
                        .background(Color.gymCard)
                        .clipShape(Capsule())
                    }
                    .accessibleButton(label: "Previous exercise")
                }

                Spacer()

                // Rest timer compact (if running but dismissed)
                if vm.timerService.isRunning && !vm.showRestTimerOverlay {
                    CompactRestTimerView(
                        remainingTime: vm.timerService.remainingTime,
                        totalDuration: vm.timerService.totalDuration,
                        onTap: {
                            HapticManager.buttonTap()
                            vm.showRestTimerOverlay = true
                        }
                    )
                    .accessibleButton(label: "Rest timer: \(vm.timerService.formattedTime) remaining", hint: "Double tap to expand timer")
                }

                Spacer()

                // Next/Complete button
                if vm.isOnLastExercise {
                    Button {
                        vm.completeWorkout(notes: workoutNotes)
                    } label: {
                        HStack {
                            Text("Finish")
                            Image(systemName: "checkmark.circle.fill")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.gymText)
                        .padding(.horizontal, AppSpacing.standard)
                        .padding(.vertical, AppSpacing.component)
                        .background(Color.gymSuccess)
                        .clipShape(Capsule())
                    }
                    .accessibleButton(label: "Finish workout", hint: "Double tap to complete and save your workout")
                } else {
                    Button {
                        vm.nextExercise()
                    } label: {
                        HStack {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.gymText)
                        .padding(.horizontal, AppSpacing.standard)
                        .padding(.vertical, AppSpacing.component)
                        .background(Color.gymPrimary)
                        .clipShape(Capsule())
                    }
                    .accessibleButton(label: "Next exercise")
                }
            }
            .padding(.horizontal, AppSpacing.standard)
            .padding(.vertical, AppSpacing.component)
        }
        .background(Color.gymBackground)
    }

    // MARK: - Setup

    private func setupViewModel() {
        guard viewModel == nil else { return }
        guard let user = currentUser else { return }

        let vm = WorkoutViewModel(modelContext: modelContext)

        // Check for existing in-progress session for this workout day
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.endTime == nil
            }
        )

        let inProgressSession = (try? modelContext.fetch(descriptor))?.first { session in
            session.workoutDay?.id == workoutDay.id &&
            !session.exerciseLogs.isEmpty
        }

        if let existingSession = inProgressSession {
            vm.resumeWorkout(session: existingSession)
        } else {
            vm.startWorkout(workoutDay: workoutDay, user: user)
        }

        viewModel = vm
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: User.self, WorkoutSplit.self, WorkoutDay.self, Exercise.self,
        PlannedExercise.self, WorkoutSession.self, ExerciseLog.self, SetLog.self,
        configurations: config
    )

    let user = User(name: "Test User")
    container.mainContext.insert(user)

    let workoutDay = WorkoutDay(name: "Push Day", dayOrder: 0)

    // Add some exercises
    let exercise1 = Exercise(
        name: "Barbell Bench Press",
        primaryMuscle: .chest,
        secondaryMuscles: [.triceps, .shoulders],
        equipment: .barbell
    )
    let exercise2 = Exercise(
        name: "Incline Dumbbell Press",
        primaryMuscle: .chest,
        equipment: .dumbbell
    )

    container.mainContext.insert(exercise1)
    container.mainContext.insert(exercise2)

    let planned1 = PlannedExercise(exerciseOrder: 0, targetSets: 3, restSeconds: 90)
    planned1.exercise = exercise1
    planned1.workoutDay = workoutDay

    let planned2 = PlannedExercise(exerciseOrder: 1, targetSets: 3, restSeconds: 90)
    planned2.exercise = exercise2
    planned2.workoutDay = workoutDay

    workoutDay.plannedExercises = [planned1, planned2]

    return NavigationStack {
        ActiveWorkoutView(workoutDay: workoutDay)
    }
    .modelContainer(container)
}
