//
//  WatchWorkoutSummaryView.swift
//  GymTrackProWatch
//
//  Workout completion summary view.
//

import SwiftUI
import WatchKit

/// View showing workout completion summary
struct WatchWorkoutSummaryView: View {
    @EnvironmentObject var viewModel: WatchWorkoutViewModel

    var body: some View {
        Group {
            if case .completed(let summary) = viewModel.workoutState {
                completedContent(summary: summary)
            } else {
                loadingView
            }
        }
        .navigationTitle("Complete!")
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack {
            ProgressView()
            Text("Saving workout...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Completed Content

    private func completedContent(summary: WorkoutCompletedDTO) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Checkmark animation
                completionHeader

                // Stats
                statsSection(summary: summary)

                // Done button
                Button(action: viewModel.returnToMain) {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding(.horizontal, 4)
        }
        .onAppear {
            // Play success haptic
            WKInterfaceDevice.current().play(.success)
        }
    }

    // MARK: - Completion Header

    private var completionHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.green)

            Text("Great Workout!")
                .font(.headline)
        }
    }

    // MARK: - Stats Section

    private func statsSection(summary: WorkoutCompletedDTO) -> some View {
        VStack(spacing: 8) {
            // Duration
            statRow(
                icon: "clock.fill",
                label: "Duration",
                value: summary.durationDisplay
            )

            // Volume
            statRow(
                icon: "scalemass.fill",
                label: "Volume",
                value: formatVolume(summary.totalVolume)
            )

            // Sets
            statRow(
                icon: "number",
                label: "Sets",
                value: "\(summary.totalSets)"
            )

            // PRs (if any)
            if summary.prsAchieved > 0 {
                statRow(
                    icon: "trophy.fill",
                    label: "PRs",
                    value: "\(summary.prsAchieved)",
                    valueColor: .yellow
                )
            }
        }
    }

    private func statRow(
        icon: String,
        label: String,
        value: String,
        valueColor: Color = .primary
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(valueColor)
        }
    }

    // MARK: - Helpers

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk kg", volume / 1000)
        }
        return String(format: "%.0f kg", volume)
    }
}

// MARK: - Preview

#Preview {
    let vm = WatchWorkoutViewModel()

    return WatchWorkoutSummaryView()
        .environmentObject(vm)
}
