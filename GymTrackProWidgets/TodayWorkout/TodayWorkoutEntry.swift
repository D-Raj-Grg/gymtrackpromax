//
//  TodayWorkoutEntry.swift
//  GymTrackProWidgets
//
//  Created by Claude Code on 30/01/26.
//

import WidgetKit

/// Timeline entry for the TodayWorkout widget.
struct TodayWorkoutEntry: TimelineEntry {
    let date: Date
    let workoutName: String?
    let muscleGroups: [String]
    let exerciseCount: Int
    let estimatedDuration: Int
    let isRestDay: Bool
}
