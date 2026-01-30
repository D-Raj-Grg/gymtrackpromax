//
//  WeeklyProgressEntry.swift
//  GymTrackProWidgets
//
//  Created by Claude Code on 30/01/26.
//

import WidgetKit

/// Timeline entry for the WeeklyProgress widget.
struct WeeklyProgressEntry: TimelineEntry {
    let date: Date
    let workoutCount: Int
    let totalVolume: Double
    let prCount: Int
    let weightUnitSymbol: String
}
