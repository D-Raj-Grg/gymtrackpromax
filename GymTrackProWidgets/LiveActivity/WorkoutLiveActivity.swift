//
//  WorkoutLiveActivity.swift
//  GymTrack Pro
//
//  Created by Claude Code on 30/01/26.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            // MARK: - Lock Screen View
            WorkoutLockScreenView(
                attributes: context.attributes,
                state: context.state
            )
            .activityBackgroundTint(Color(red: 0x0F / 255, green: 0x17 / 255, blue: 0x2A / 255))
            .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Expanded View
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Exercise \(context.state.currentExerciseNumber) of \(context.attributes.totalExercises)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(context.attributes.workoutName)
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Image(systemName: "timer")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(context.attributes.startTime, style: .timer)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.white)
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.currentExerciseName)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text("\(context.state.setsCompleted)/\(context.state.targetSets) sets")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)

                        Spacer()

                        if context.state.isResting,
                           let start = context.state.restTimerStart,
                           let end = context.state.restTimerEnd {
                            Label {
                                Text(timerInterval: start...end, countsDown: true)
                                    .font(.subheadline.monospacedDigit())
                            } icon: {
                                Image(systemName: "hourglass")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.cyan)
                        } else {
                            Text("\(context.state.totalSetsLogged) logged")
                                .font(.subheadline)
                                .foregroundStyle(.green)
                        }
                    }
                }

            } compactLeading: {
                // MARK: - Compact Leading
                HStack(spacing: 4) {
                    Image(systemName: "dumbbell.fill")
                        .font(.caption2)
                    Text("\(context.state.currentExerciseNumber)/\(context.attributes.totalExercises)")
                        .font(.caption.monospacedDigit().weight(.semibold))
                }
                .foregroundStyle(.cyan)

            } compactTrailing: {
                // MARK: - Compact Trailing
                if context.state.isResting,
                   let start = context.state.restTimerStart,
                   let end = context.state.restTimerEnd {
                    Text(timerInterval: start...end, countsDown: true)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.cyan)
                        .frame(minWidth: 36)
                } else {
                    Text(context.attributes.startTime, style: .timer)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white)
                        .frame(minWidth: 36)
                }

            } minimal: {
                // MARK: - Minimal
                Image(systemName: "dumbbell.fill")
                    .font(.caption2)
                    .foregroundStyle(.cyan)
            }
        }
    }
}
