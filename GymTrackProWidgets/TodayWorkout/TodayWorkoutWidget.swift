//
//  TodayWorkoutWidget.swift
//  GymTrackProWidgets
//
//  Created by Claude Code on 30/01/26.
//

import WidgetKit
import SwiftUI

/// Widget showing today's scheduled workout. Supports small and medium sizes.
struct TodayWorkoutWidget: Widget {
    let kind: String = "TodayWorkoutWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayWorkoutProvider()) { entry in
            TodayWorkoutView(entry: entry)
        }
        .configurationDisplayName("Today's Workout")
        .description("See what workout is scheduled for today.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Provider

struct TodayWorkoutProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayWorkoutEntry {
        TodayWorkoutEntry(
            date: .now,
            workoutName: "Push Day",
            muscleGroups: ["Chest", "Shoulders", "Triceps"],
            exerciseCount: 6,
            estimatedDuration: 55,
            isRestDay: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayWorkoutEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        let data = WidgetDataProvider.fetchData()
        completion(makeEntry(from: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayWorkoutEntry>) -> Void) {
        let data = WidgetDataProvider.fetchData()
        let entry = makeEntry(from: data)

        // Refresh at midnight when the workout day changes
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: .now)!)
        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }

    private func makeEntry(from data: WidgetDataProvider.WidgetData) -> TodayWorkoutEntry {
        TodayWorkoutEntry(
            date: .now,
            workoutName: data.todayWorkoutName,
            muscleGroups: data.todayMuscleGroups,
            exerciseCount: data.todayExerciseCount,
            estimatedDuration: data.todayEstimatedDuration,
            isRestDay: data.isRestDay
        )
    }
}
