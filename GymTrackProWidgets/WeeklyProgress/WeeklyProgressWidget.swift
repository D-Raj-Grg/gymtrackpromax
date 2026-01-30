//
//  WeeklyProgressWidget.swift
//  GymTrackProWidgets
//
//  Created by Claude Code on 30/01/26.
//

import WidgetKit
import SwiftUI

/// Medium widget showing weekly workout statistics.
struct WeeklyProgressWidget: Widget {
    let kind: String = "WeeklyProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeeklyProgressProvider()) { entry in
            WeeklyProgressView(entry: entry)
        }
        .configurationDisplayName("Weekly Progress")
        .description("See your workout stats for the current week.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Provider

struct WeeklyProgressProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeeklyProgressEntry {
        WeeklyProgressEntry(
            date: .now,
            workoutCount: 4,
            totalVolume: 12500,
            prCount: 2,
            weightUnitSymbol: "kg"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WeeklyProgressEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        let data = WidgetDataProvider.fetchData()
        completion(makeEntry(from: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeeklyProgressEntry>) -> Void) {
        let data = WidgetDataProvider.fetchData()
        let entry = makeEntry(from: data)

        // Refresh at midnight
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: .now)!)
        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }

    private func makeEntry(from data: WidgetDataProvider.WidgetData) -> WeeklyProgressEntry {
        WeeklyProgressEntry(
            date: .now,
            workoutCount: data.weeklyWorkoutCount,
            totalVolume: data.weeklyVolume,
            prCount: data.weeklyPRCount,
            weightUnitSymbol: data.weightUnitSymbol
        )
    }
}
