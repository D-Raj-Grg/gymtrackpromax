//
//  WatchWorkoutListView.swift
//  GymTrackProWatch
//
//  Main view showing today's workout on the Watch.
//

import SwiftUI
import WatchKit

/// Main view for the Watch app - shows today's workout
struct WatchWorkoutListView: View {
    @EnvironmentObject var viewModel: WatchWorkoutViewModel

    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            contentView
                .navigationTitle("GymTrack")
                .navigationDestination(for: WatchNavigationDestination.self) { destination in
                    switch destination {
                    case .activeWorkout:
                        WatchActiveWorkoutView()
                            .environmentObject(viewModel)
                    case .summary:
                        WatchWorkoutSummaryView()
                            .environmentObject(viewModel)
                    }
                }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.dismissError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.todayState {
        case .loading:
            loadingView

        case .restDay(let message):
            restDayView(message: message)

        case .workout(let workout):
            workoutView(workout: workout)

        case .error(let error):
            errorView(error: error)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 8) {
            ProgressView()
                .tint(.blue)

            Text("Loading...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Rest Day View

    private func restDayView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "bed.double.fill")
                .font(.system(size: 40))
                .foregroundStyle(.green)

            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("Take it easy today!")
                .font(.caption)
                .foregroundStyle(.secondary)

            if !viewModel.isPhoneReachable {
                phoneUnreachableLabel
            }
        }
        .padding()
    }

    // MARK: - Workout View

    private func workoutView(workout: TodayWorkoutDTO) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Workout name
                Text(workout.workoutName)
                    .font(.headline)
                    .foregroundStyle(.primary)

                // Muscle groups
                Text(workout.muscleGroups.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Stats
                HStack {
                    Label("\(workout.exerciseCount)", systemImage: "dumbbell.fill")
                        .font(.caption2)

                    Spacer()

                    Label("~\(workout.estimatedDuration)m", systemImage: "clock")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)

                Divider()

                // Action buttons
                if workout.hasInProgressSession {
                    // Continue workout button
                    Button(action: viewModel.continueWorkout) {
                        Label("Continue", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                } else {
                    // Start workout button
                    Button(action: {
                        #if targetEnvironment(simulator)
                        if viewModel.isSimulatorMockMode {
                            viewModel.startMockWorkout()
                        } else {
                            viewModel.startWorkout()
                        }
                        #else
                        viewModel.startWorkout()
                        #endif
                    }) {
                        Label("Start Workout", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }

                if !viewModel.isPhoneReachable {
                    phoneUnreachableLabel
                }

                #if targetEnvironment(simulator)
                if viewModel.isSimulatorMockMode {
                    simulatorModeLabel
                }
                #endif
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Simulator Mode Label

    #if targetEnvironment(simulator)
    private var simulatorModeLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: "ladybug.fill")
                .font(.caption2)
            Text("Simulator Mode")
                .font(.caption2)
        }
        .foregroundStyle(.purple)
        .padding(.top, 4)
    }
    #endif

    // MARK: - Error View

    private func errorView(error: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.yellow)

            Text("Something went wrong")
                .font(.headline)

            Text(error)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                viewModel.refreshTodayWorkout()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    // MARK: - Phone Unreachable Label

    private var phoneUnreachableLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: "iphone.slash")
                .font(.caption2)
            Text("iPhone not connected")
                .font(.caption2)
        }
        .foregroundStyle(.orange)
        .padding(.top, 4)
    }
}

#Preview {
    WatchWorkoutListView()
        .environmentObject(WatchWorkoutViewModel())
}
