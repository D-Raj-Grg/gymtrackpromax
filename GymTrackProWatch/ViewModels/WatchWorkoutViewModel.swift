//
//  WatchWorkoutViewModel.swift
//  GymTrackProWatch
//
//  ViewModel for managing workout state on the Watch.
//

import Combine
import Foundation
import SwiftUI
import WatchKit

/// ViewModel for the Watch app workout flow
@MainActor
final class WatchWorkoutViewModel: ObservableObject {
    // MARK: - Published State

    /// Today's workout state
    @Published var todayState: WatchTodayState = .loading

    /// Active workout state
    @Published var workoutState: WatchWorkoutState = .idle

    /// Current exercise index
    @Published var currentExerciseIndex: Int = 0

    /// Set input values
    @Published var setInput = WatchSetInput()

    /// Which input field has focus
    @Published var inputFocus: WatchInputFocus = .weight

    /// Navigation path
    @Published var navigationPath = NavigationPath()

    /// Whether to show PR celebration
    @Published var showPRCelebration: Bool = false

    /// Latest PR info
    @Published var latestPR: PRInfoDTO?

    /// Error message to display
    @Published var errorMessage: String?

    /// Whether the phone is reachable
    @Published var isPhoneReachable: Bool = false

    // MARK: - Computed Properties

    /// Current exercise from workout state
    var currentExercise: ExerciseStateDTO? {
        guard case .active(let state) = workoutState,
              currentExerciseIndex < state.exercises.count else {
            return nil
        }
        return state.exercises[currentExerciseIndex]
    }

    /// Whether we're on the last exercise
    var isOnLastExercise: Bool {
        guard case .active(let state) = workoutState else { return true }
        return currentExerciseIndex >= state.exercises.count - 1
    }

    /// Whether we have a previous exercise
    var hasPreviousExercise: Bool {
        currentExerciseIndex > 0
    }

    /// Total exercises count
    var totalExercises: Int {
        guard case .active(let state) = workoutState else { return 0 }
        return state.exercises.count
    }

    /// Elapsed time display
    var elapsedTimeDisplay: String {
        guard case .active(let state) = workoutState else { return "00:00" }
        let elapsed = Int(Date().timeIntervalSince(state.startTime))
        let hours = elapsed / 3600
        let minutes = (elapsed % 3600) / 60
        let seconds = elapsed % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Private Properties

    private let connectivityService = WatchConnectivityService.shared

    // MARK: - Initialization

    init() {
        setupConnectivityCallbacks()
        connectivityService.activate()

        // Set a timeout to show error or mock data if no data received
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            if case .loading = todayState {
                #if targetEnvironment(simulator)
                // In simulator, WatchConnectivity often fails - use mock data for UI testing
                print("[WatchViewModel] Simulator timeout - loading mock data for UI testing")
                loadMockDataForSimulator()
                #else
                if !isPhoneReachable {
                    todayState = .error("iPhone not reachable. Please open GymTrack Pro on your iPhone.")
                }
                #endif
            }
        }
    }

    // MARK: - Setup

    private func setupConnectivityCallbacks() {
        connectivityService.onTodayWorkoutReceived = { [weak self] dto in
            self?.todayState = .workout(dto)

            // If there's an in-progress session, request state
            if dto.hasInProgressSession {
                self?.connectivityService.requestWorkoutState()
            }
        }

        connectivityService.onRestDayReceived = { [weak self] dto in
            self?.todayState = .restDay(message: dto.message)
        }

        connectivityService.onWorkoutStateReceived = { [weak self] dto in
            self?.handleWorkoutStateReceived(dto)
        }

        connectivityService.onSetLogConfirmationReceived = { [weak self] dto in
            self?.handleSetLogConfirmation(dto)
        }

        connectivityService.onWorkoutCompletedReceived = { [weak self] dto in
            self?.workoutState = .completed(dto)
            self?.navigationPath.append(WatchNavigationDestination.summary)
        }

        connectivityService.onErrorReceived = { [weak self] error in
            self?.errorMessage = error
        }

        // Observe reachability
        connectivityService.$isPhoneReachable
            .receive(on: DispatchQueue.main)
            .assign(to: &$isPhoneReachable)
    }

    // MARK: - Actions

    /// Refresh today's workout
    func refreshTodayWorkout() {
        todayState = .loading
        connectivityService.requestTodayWorkout()
    }

    /// Start a workout
    func startWorkout() {
        guard case .workout(let today) = todayState else { return }

        workoutState = .loading
        connectivityService.startWorkout(workoutDayId: today.workoutDayId)
    }

    /// Continue an in-progress workout
    func continueWorkout() {
        guard case .workout(let today) = todayState,
              today.hasInProgressSession else { return }

        workoutState = .loading
        connectivityService.requestWorkoutState()
    }

    /// Log the current set
    func logSet() {
        guard let exercise = currentExercise else { return }

        connectivityService.logSet(
            exerciseLogId: exercise.exerciseLogId,
            weight: setInput.weight,
            reps: setInput.reps,
            isWarmup: setInput.isWarmup
        )

        // Haptic feedback
        WKInterfaceDevice.current().play(.success)
    }

    /// Move to next exercise
    func nextExercise() {
        guard !isOnLastExercise else { return }

        currentExerciseIndex += 1
        updateSetInputForCurrentExercise()

        // Haptic
        WKInterfaceDevice.current().play(.click)
    }

    /// Move to previous exercise
    func previousExercise() {
        guard hasPreviousExercise else { return }

        currentExerciseIndex -= 1
        updateSetInputForCurrentExercise()

        // Haptic
        WKInterfaceDevice.current().play(.click)
    }

    /// Complete the workout
    func completeWorkout() {
        connectivityService.completeWorkout()
    }

    /// Toggle input focus between weight and reps
    func toggleInputFocus() {
        inputFocus = inputFocus == .weight ? .reps : .weight
        WKInterfaceDevice.current().play(.click)
    }

    /// Increment weight
    func incrementWeight() {
        setInput.weight += WatchSetInput.weightIncrement
        WKInterfaceDevice.current().play(.click)
    }

    /// Decrement weight
    func decrementWeight() {
        setInput.weight = max(0, setInput.weight - WatchSetInput.weightIncrement)
        WKInterfaceDevice.current().play(.click)
    }

    /// Increment reps
    func incrementReps() {
        setInput.reps += 1
        WKInterfaceDevice.current().play(.click)
    }

    /// Decrement reps
    func decrementReps() {
        setInput.reps = max(1, setInput.reps - 1)
        WKInterfaceDevice.current().play(.click)
    }

    /// Toggle warmup
    func toggleWarmup() {
        setInput.isWarmup.toggle()
        WKInterfaceDevice.current().play(.click)
    }

    /// Dismiss error
    func dismissError() {
        errorMessage = nil
    }

    /// Dismiss PR celebration
    func dismissPRCelebration() {
        showPRCelebration = false
        latestPR = nil
    }

    /// Return to main screen after workout complete
    func returnToMain() {
        workoutState = .idle
        currentExerciseIndex = 0
        navigationPath = NavigationPath()
        refreshTodayWorkout()
    }

    // MARK: - Private Methods

    private func handleWorkoutStateReceived(_ dto: WorkoutStateDTO) {
        workoutState = .active(dto)

        // Navigate to active workout if not already there
        if !navigationPath.isEmpty {
            // Already navigating
        } else {
            navigationPath.append(WatchNavigationDestination.activeWorkout)
        }

        // Update set input for current exercise
        updateSetInputForCurrentExercise()
    }

    private func handleSetLogConfirmation(_ dto: SetLogConfirmationDTO) {
        if dto.success {
            // Update state with new data
            if let updatedState = dto.updatedState {
                workoutState = .active(updatedState)
            }

            // Handle PR
            if dto.isPR, let prInfo = dto.prInfo {
                latestPR = prInfo
                showPRCelebration = true

                // Strong haptic for PR
                WKInterfaceDevice.current().play(.notification)
            }

            // Reset warmup flag
            setInput.isWarmup = false
        } else {
            errorMessage = dto.errorMessage ?? "Failed to log set"
        }
    }

    private func updateSetInputForCurrentExercise() {
        guard let exercise = currentExercise else { return }

        setInput.reset(
            suggestedWeight: exercise.suggestedWeight,
            suggestedReps: (exercise.targetRepsMin + exercise.targetRepsMax) / 2
        )
    }

    // MARK: - Simulator Mock Data

    #if targetEnvironment(simulator)
    /// Load mock data for simulator testing when WatchConnectivity fails
    private func loadMockDataForSimulator() {
        // Create mock today's workout
        let mockWorkout = TodayWorkoutDTO(
            workoutDayId: UUID().uuidString,
            workoutName: "Push Day (Mock)",
            muscleGroups: ["Chest", "Shoulders", "Triceps"],
            exerciseCount: 5,
            estimatedDuration: 45,
            hasInProgressSession: false,
            sessionId: nil
        )
        todayState = .workout(mockWorkout)
    }

    /// Start mock workout for simulator testing
    func startMockWorkout() {
        let mockExercises = [
            ExerciseStateDTO(
                exerciseLogId: UUID().uuidString,
                exerciseName: "Bench Press",
                muscleGroup: "Chest",
                targetSets: 4,
                targetRepsMin: 6,
                targetRepsMax: 8,
                completedSets: [],
                suggestedWeight: 60,
                suggestedReps: 7,
                previousBest: "57.5kg × 8",
                isInSuperset: false,
                supersetPosition: nil
            ),
            ExerciseStateDTO(
                exerciseLogId: UUID().uuidString,
                exerciseName: "Incline Dumbbell Press",
                muscleGroup: "Chest",
                targetSets: 3,
                targetRepsMin: 8,
                targetRepsMax: 12,
                completedSets: [],
                suggestedWeight: 22.5,
                suggestedReps: 10,
                previousBest: "20kg × 10",
                isInSuperset: false,
                supersetPosition: nil
            ),
            ExerciseStateDTO(
                exerciseLogId: UUID().uuidString,
                exerciseName: "Overhead Press",
                muscleGroup: "Shoulders",
                targetSets: 4,
                targetRepsMin: 6,
                targetRepsMax: 8,
                completedSets: [],
                suggestedWeight: 40,
                suggestedReps: 7,
                previousBest: "37.5kg × 8",
                isInSuperset: false,
                supersetPosition: nil
            ),
            ExerciseStateDTO(
                exerciseLogId: UUID().uuidString,
                exerciseName: "Lateral Raises",
                muscleGroup: "Shoulders",
                targetSets: 3,
                targetRepsMin: 12,
                targetRepsMax: 15,
                completedSets: [],
                suggestedWeight: 10,
                suggestedReps: 12,
                previousBest: "8kg × 15",
                isInSuperset: false,
                supersetPosition: nil
            ),
            ExerciseStateDTO(
                exerciseLogId: UUID().uuidString,
                exerciseName: "Tricep Pushdowns",
                muscleGroup: "Triceps",
                targetSets: 3,
                targetRepsMin: 10,
                targetRepsMax: 12,
                completedSets: [],
                suggestedWeight: 25,
                suggestedReps: 11,
                previousBest: "22.5kg × 12",
                isInSuperset: false,
                supersetPosition: nil
            )
        ]

        let mockState = WorkoutStateDTO(
            sessionId: UUID().uuidString,
            workoutName: "Push Day (Mock)",
            startTime: Date(),
            currentExerciseIndex: 0,
            exercises: mockExercises,
            totalVolume: 0,
            totalSetsLogged: 0
        )

        workoutState = .active(mockState)
        currentExerciseIndex = 0
        updateSetInputForCurrentExercise()
        navigationPath.append(WatchNavigationDestination.activeWorkout)
    }

    /// Log a mock set for simulator testing
    func logMockSet() {
        guard case .active(let state) = workoutState,
              currentExerciseIndex < state.exercises.count else { return }

        // Add the set to current exercise
        let exercise = state.exercises[currentExerciseIndex]
        let newSet = SetDTO(
            setId: UUID().uuidString,
            setNumber: exercise.completedSets.count + 1,
            weight: setInput.weight,
            reps: setInput.reps,
            isWarmup: setInput.isWarmup,
            isPR: false
        )

        var updatedSets = exercise.completedSets
        updatedSets.append(newSet)

        // Update the exercise with new sets
        let updatedExercise = ExerciseStateDTO(
            exerciseLogId: exercise.exerciseLogId,
            exerciseName: exercise.exerciseName,
            muscleGroup: exercise.muscleGroup,
            targetSets: exercise.targetSets,
            targetRepsMin: exercise.targetRepsMin,
            targetRepsMax: exercise.targetRepsMax,
            completedSets: updatedSets,
            suggestedWeight: exercise.suggestedWeight,
            suggestedReps: exercise.suggestedReps,
            previousBest: exercise.previousBest,
            isInSuperset: exercise.isInSuperset,
            supersetPosition: exercise.supersetPosition
        )

        // Create new exercises array with updated exercise
        var updatedExercises = state.exercises
        updatedExercises[currentExerciseIndex] = updatedExercise

        // Update totals
        let newVolume = state.totalVolume + (setInput.weight * Double(setInput.reps))
        let updatedState = WorkoutStateDTO(
            sessionId: state.sessionId,
            workoutName: state.workoutName,
            startTime: state.startTime,
            currentExerciseIndex: state.currentExerciseIndex,
            exercises: updatedExercises,
            totalVolume: newVolume,
            totalSetsLogged: state.totalSetsLogged + 1
        )

        workoutState = .active(updatedState)

        // Haptic feedback
        WKInterfaceDevice.current().play(.success)

        // Reset warmup
        setInput.isWarmup = false
    }

    /// Complete mock workout
    func completeMockWorkout() {
        guard case .active(let state) = workoutState else { return }

        let completedDTO = WorkoutCompletedDTO(
            sessionId: state.sessionId,
            duration: Date().timeIntervalSince(state.startTime),
            totalVolume: state.totalVolume,
            totalSets: state.totalSetsLogged,
            exercisesCompleted: state.exercises.filter { !$0.completedSets.isEmpty }.count,
            prsAchieved: 0
        )

        workoutState = .completed(completedDTO)
        navigationPath.append(WatchNavigationDestination.summary)
    }

    /// Check if running in simulator mock mode
    var isSimulatorMockMode: Bool {
        if case .workout(let workout) = todayState {
            return workout.workoutName.contains("(Mock)")
        }
        if case .active(let state) = workoutState {
            return state.workoutName.contains("(Mock)")
        }
        return false
    }
    #endif
}
