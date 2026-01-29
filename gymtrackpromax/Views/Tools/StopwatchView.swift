//
//  StopwatchView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

struct StopwatchView: View {
    // MARK: - State

    @State private var stopwatchService = StopwatchService()

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Time display
            timeDisplay
                .padding(.top, AppSpacing.xl)

            // Current lap time
            if stopwatchService.isRunning || stopwatchService.elapsedTime > 0 {
                currentLapDisplay
                    .padding(.top, AppSpacing.small)
            }

            Spacer()

            // Control buttons
            controlButtons
                .padding(.vertical, AppSpacing.section)

            // Lap list
            lapList
        }
        .background(Color.gymBackground)
        .navigationTitle("Stopwatch")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Time Display

    private var timeDisplay: some View {
        Text(stopwatchService.formattedTime)
            .font(.system(size: 64, weight: .bold, design: .monospaced))
            .foregroundStyle(Color.gymText)
            .accessibilityLabel("Elapsed time: \(stopwatchService.formattedTime)")
    }

    private var currentLapDisplay: some View {
        HStack(spacing: AppSpacing.small) {
            Text("Lap \(stopwatchService.laps.count + 1)")
                .font(.subheadline)
                .foregroundStyle(Color.gymTextMuted)

            Text(stopwatchService.formattedLapTime)
                .font(.system(.title3, design: .monospaced))
                .fontWeight(.medium)
                .foregroundStyle(Color.gymAccent)
        }
    }

    // MARK: - Control Buttons

    private var controlButtons: some View {
        HStack(spacing: AppSpacing.xl) {
            // Reset/Lap button
            Button {
                HapticManager.buttonTap()
                if stopwatchService.isRunning {
                    stopwatchService.lap()
                } else {
                    stopwatchService.reset()
                }
            } label: {
                Text(stopwatchService.isRunning ? "Lap" : "Reset")
                    .font(.headline)
                    .foregroundStyle(Color.gymText)
                    .frame(width: 80, height: 80)
                    .background(Color.gymCard)
                    .clipShape(Circle())
            }
            .opacity(stopwatchService.elapsedTime > 0 || stopwatchService.isRunning ? 1 : 0.5)
            .disabled(stopwatchService.elapsedTime == 0 && !stopwatchService.isRunning)
            .accessibleButton(
                label: stopwatchService.isRunning ? "Record lap" : "Reset stopwatch"
            )

            // Start/Stop button
            Button {
                HapticManager.buttonTap()
                if stopwatchService.isRunning {
                    stopwatchService.stop()
                } else {
                    stopwatchService.start()
                }
            } label: {
                Text(stopwatchService.isRunning ? "Stop" : "Start")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.white)
                    .frame(width: 80, height: 80)
                    .background(stopwatchService.isRunning ? Color.gymError : Color.gymSuccess)
                    .clipShape(Circle())
            }
            .accessibleButton(
                label: stopwatchService.isRunning ? "Stop stopwatch" : "Start stopwatch"
            )
        }
    }

    // MARK: - Lap List

    private var lapList: some View {
        Group {
            if stopwatchService.laps.isEmpty {
                VStack(spacing: AppSpacing.small) {
                    Text("No laps recorded")
                        .font(.subheadline)
                        .foregroundStyle(Color.gymTextMuted)

                    Text("Tap Lap while running to record")
                        .font(.caption)
                        .foregroundStyle(Color.gymTextMuted.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, AppSpacing.xl)
            } else {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Lap")
                            .frame(width: 60, alignment: .leading)
                        Spacer()
                        Text("Lap Time")
                        Spacer()
                        Text("Total")
                            .frame(width: 100, alignment: .trailing)
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.gymTextMuted)
                    .padding(.horizontal, AppSpacing.standard)
                    .padding(.vertical, AppSpacing.small)

                    Divider()
                        .background(Color.gymBorder)

                    // Lap rows
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(stopwatchService.laps) { lap in
                                LapRow(lap: lap, allLaps: stopwatchService.laps)
                            }
                        }
                    }
                }
                .background(Color.gymCard)
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
                .padding(.horizontal, AppSpacing.standard)
                .padding(.bottom, AppSpacing.standard)
            }
        }
    }
}

// MARK: - Lap Row

private struct LapRow: View {
    let lap: StopwatchService.Lap
    let allLaps: [StopwatchService.Lap]

    private var lapColor: Color {
        guard allLaps.count > 1 else { return .gymText }

        let fastestLap = allLaps.min(by: { $0.lapTime < $1.lapTime })
        let slowestLap = allLaps.max(by: { $0.lapTime < $1.lapTime })

        if lap.id == fastestLap?.id {
            return .gymSuccess
        } else if lap.id == slowestLap?.id {
            return .gymError
        }
        return .gymText
    }

    var body: some View {
        HStack {
            Text("\(lap.number)")
                .frame(width: 60, alignment: .leading)
                .foregroundStyle(Color.gymTextMuted)

            Spacer()

            Text(formatTime(lap.lapTime))
                .foregroundStyle(lapColor)

            Spacer()

            Text(formatTime(lap.totalTime))
                .frame(width: 100, alignment: .trailing)
                .foregroundStyle(Color.gymTextMuted)
        }
        .font(.system(.body, design: .monospaced))
        .padding(.horizontal, AppSpacing.standard)
        .padding(.vertical, AppSpacing.component)
        .accessibleCard(label: "Lap \(lap.number), lap time \(formatTime(lap.lapTime)), total \(formatTime(lap.totalTime))")
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let centiseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, centiseconds)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        StopwatchView()
    }
}
