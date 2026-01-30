//
//  StreakEntry.swift
//  GymTrackProWidgets
//
//  Created by Claude Code on 30/01/26.
//

import WidgetKit

/// Timeline entry for the Streak widget.
struct StreakEntry: TimelineEntry {
    let date: Date
    let streakCount: Int
}
