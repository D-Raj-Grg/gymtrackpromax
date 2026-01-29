//
//  RestTimerOverlay.swift
//  GymTrack Pro
//
//  Created by Claude Code on 28/01/26.
//

import SwiftUI

struct RestTimerOverlay: View {
    // MARK: - Properties

    @Bindable var timerService: TimerService
    let nextExercise: PlannedExercise?
    let onDismiss: () -> Void

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background blur
            Color.gymBackground.opacity(0.95)
                .ignoresSafeArea()
                .onTapGesture {
                    // Don't dismiss on tap
                }

            VStack(spacing: AppSpacing.section) {
                // Header with dismiss
                HStack {
                    Spacer()

                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundStyle(Color.gymTextMuted)
                            .frame(width: 36, height: 36)
                            .background(Color.gymCard)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, AppSpacing.standard)

                Spacer()

                // Title
                Text("Rest Time")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.gymTextMuted)

                // Timer
                RestTimerView(
                    remainingTime: timerService.remainingTime,
                    totalDuration: timerService.totalDuration,
                    isRunning: timerService.isRunning,
                    isPaused: timerService.isPaused,
                    onPause: { timerService.pause() },
                    onResume: { timerService.resume() },
                    onAddTime: { timerService.addTime($0) },
                    onSkip: {
                        timerService.skip()
                        onDismiss()
                    }
                )

                Spacer()

                // Next exercise preview
                if let next = nextExercise {
                    VStack(spacing: AppSpacing.small) {
                        Text("Up Next")
                            .font(.caption)
                            .foregroundStyle(Color.gymTextMuted)

                        Text(next.exerciseName)
                            .font(.headline)
                            .foregroundStyle(Color.gymText)

                        Text(next.setsAndRepsDisplay)
                            .font(.subheadline)
                            .foregroundStyle(Color.gymTextMuted)
                    }
                    .padding(AppSpacing.standard)
                    .frame(maxWidth: .infinity)
                    .background(Color.gymCard)
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
                    .padding(.horizontal, AppSpacing.standard)
                }

                Spacer()
            }
            .padding(.vertical, AppSpacing.standard)
        }
        .onChange(of: timerService.isCompleted) { _, isCompleted in
            if isCompleted {
                onDismiss()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let timerService = TimerService()

    RestTimerOverlay(
        timerService: timerService,
        nextExercise: nil,
        onDismiss: {}
    )
    .onAppear {
        timerService.start(duration: 90)
    }
}
