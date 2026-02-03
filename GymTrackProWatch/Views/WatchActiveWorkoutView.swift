//
//  WatchActiveWorkoutView.swift
//  GymTrackProWatch
//
//  Active workout view for the Watch showing current exercise.
//

import SwiftUI
import WatchKit

/// Container view for an active workout
struct WatchActiveWorkoutView: View {
    @EnvironmentObject var viewModel: WatchWorkoutViewModel
    @State private var showCompleteConfirmation = false

    var body: some View {
        Group {
            switch viewModel.workoutState {
            case .loading:
                loadingView

            case .active(let state):
                activeWorkoutContent(state: state)

            case .completed:
                // Handled by navigation
                EmptyView()

            case .idle, .error:
                errorView
            }
        }
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: { showCompleteConfirmation = true }) {
                    Image(systemName: "checkmark.circle")
                }
                .tint(.green)
            }
        }
        .confirmationDialog(
            "Finish Workout?",
            isPresented: $showCompleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Finish", role: .destructive) {
                #if targetEnvironment(simulator)
                if viewModel.isSimulatorMockMode {
                    viewModel.completeMockWorkout()
                } else {
                    viewModel.completeWorkout()
                }
                #else
                viewModel.completeWorkout()
                #endif
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $viewModel.showPRCelebration) {
            prCelebrationView
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack {
            ProgressView()
            Text("Starting workout...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Error View

    private var errorView: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundStyle(.yellow)

            Text("Unable to load workout")
                .font(.caption)
        }
    }

    // MARK: - Active Workout Content

    private func activeWorkoutContent(state: WorkoutStateDTO) -> some View {
        TabView(selection: $viewModel.currentExerciseIndex) {
            ForEach(Array(state.exercises.enumerated()), id: \.element.exerciseLogId) { index, exercise in
                WatchExerciseView(exercise: exercise)
                    .environmentObject(viewModel)
                    .tag(index)
            }
        }
        .tabViewStyle(.verticalPage)
    }

    // MARK: - PR Celebration View

    private var prCelebrationView: some View {
        VStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 50))
                .foregroundStyle(.yellow)

            Text("NEW PR!")
                .font(.headline)
                .foregroundStyle(.yellow)

            if let pr = viewModel.latestPR {
                Text(pr.exerciseName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(String(format: "+%.1f kg", pr.improvement))
                    .font(.title3)
                    .fontWeight(.bold)
            }

            Button("Awesome!") {
                viewModel.dismissPRCelebration()
            }
            .buttonStyle(.borderedProminent)
            .tint(.yellow)
        }
        .padding()
    }
}

#Preview {
    WatchActiveWorkoutView()
        .environmentObject(WatchWorkoutViewModel())
}
