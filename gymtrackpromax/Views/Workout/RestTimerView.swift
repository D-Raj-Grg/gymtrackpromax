//
//  RestTimerView.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

struct RestTimerView: View {
    // MARK: - Properties

    let remainingTime: TimeInterval
    let totalDuration: TimeInterval
    let isRunning: Bool
    let isPaused: Bool

    let onPause: () -> Void
    let onResume: () -> Void
    let onAddTime: (TimeInterval) -> Void
    let onSkip: () -> Void

    // MARK: - Computed

    private var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1.0 - (remainingTime / totalDuration)
    }

    private var formattedTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: AppSpacing.section) {
            // Circular progress timer
            circularTimer

            // Controls
            timerControls
        }
    }

    // MARK: - Circular Timer

    private var circularTimer: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gymCardHover, lineWidth: 12)
                .frame(width: 200, height: 200)

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    timerColor,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: progress)

            // Time display
            VStack(spacing: AppSpacing.xs) {
                Text(formattedTime)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.gymText)

                if isPaused {
                    Text("PAUSED")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.gymWarning)
                }
            }
        }
    }

    private var timerColor: Color {
        if remainingTime <= 10 {
            return Color.gymError
        } else if remainingTime <= 30 {
            return Color.gymWarning
        }
        return Color.gymPrimary
    }

    // MARK: - Controls

    private var timerControls: some View {
        VStack(spacing: AppSpacing.standard) {
            // Time adjustment buttons
            HStack(spacing: AppSpacing.section) {
                // -30s button
                Button {
                    HapticManager.buttonTap()
                    onAddTime(-30)
                } label: {
                    Text("-30s")
                        .font(.headline)
                        .foregroundStyle(Color.gymText)
                        .frame(width: 70, height: 44)
                        .background(Color.gymCardHover)
                        .clipShape(Capsule())
                }
                .accessibleButton(label: "Subtract 30 seconds")

                // Pause/Resume button
                Button {
                    HapticManager.buttonTap()
                    if isPaused {
                        onResume()
                    } else {
                        onPause()
                    }
                } label: {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.title2)
                        .foregroundStyle(Color.gymText)
                        .frame(width: 60, height: 60)
                        .background(Color.gymPrimary)
                        .clipShape(Circle())
                }
                .accessibleButton(label: isPaused ? "Resume timer" : "Pause timer")

                // +30s button
                Button {
                    HapticManager.buttonTap()
                    onAddTime(30)
                } label: {
                    Text("+30s")
                        .font(.headline)
                        .foregroundStyle(Color.gymText)
                        .frame(width: 70, height: 44)
                        .background(Color.gymCardHover)
                        .clipShape(Capsule())
                }
                .accessibleButton(label: "Add 30 seconds")
            }

            // Skip button
            Button {
                HapticManager.buttonTap()
                onSkip()
            } label: {
                Text("Skip")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.gymTextMuted)
            }
            .padding(.top, AppSpacing.small)
            .accessibleButton(label: "Skip rest timer")
        }
    }
}

// MARK: - Compact Timer View

struct CompactRestTimerView: View {
    let remainingTime: TimeInterval
    let totalDuration: TimeInterval
    let onTap: () -> Void

    private var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1.0 - (remainingTime / totalDuration)
    }

    private var formattedTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.small) {
                // Mini progress circle
                ZStack {
                    Circle()
                        .stroke(Color.gymCardHover, lineWidth: 3)
                        .frame(width: 24, height: 24)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.gymPrimary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 24, height: 24)
                        .rotationEffect(.degrees(-90))
                }

                Text(formattedTime)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.gymText)
            }
            .padding(.horizontal, AppSpacing.component)
            .padding(.vertical, AppSpacing.small)
            .background(Color.gymCard)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Preview

#Preview("Full Timer") {
    VStack {
        RestTimerView(
            remainingTime: 75,
            totalDuration: 90,
            isRunning: true,
            isPaused: false,
            onPause: {},
            onResume: {},
            onAddTime: { _ in },
            onSkip: {}
        )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gymBackground)
}

#Preview("Compact Timer") {
    CompactRestTimerView(
        remainingTime: 45,
        totalDuration: 90,
        onTap: {}
    )
    .padding()
    .background(Color.gymBackground)
}
