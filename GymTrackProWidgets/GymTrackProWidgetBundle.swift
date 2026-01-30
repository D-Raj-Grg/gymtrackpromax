//
//  GymTrackProWidgetBundle.swift
//  GymTrackProWidgets
//
//  Created by Claude Code on 30/01/26.
//

import WidgetKit
import SwiftUI

@main
struct GymTrackProWidgetBundle: WidgetBundle {
    var body: some Widget {
        StreakWidget()
        TodayWorkoutWidget()
        WeeklyProgressWidget()
        WorkoutLiveActivity()
    }
}
