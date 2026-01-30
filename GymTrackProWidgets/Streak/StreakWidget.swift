//
//  StreakWidget.swift
//  GymTrackProWidgets
//
//  Created by Claude Code on 30/01/26.
//

import WidgetKit
import SwiftUI

/// Small widget displaying the user's current workout streak.
struct StreakWidget: Widget {
    let kind: String = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakView(entry: entry)
        }
        .configurationDisplayName("Workout Streak")
        .description("Track your consecutive workout days.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Provider

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: .now, streakCount: 7)
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        if context.isPreview {
            completion(StreakEntry(date: .now, streakCount: 7))
            return
        }
        let data = WidgetDataProvider.fetchData()
        completion(StreakEntry(date: .now, streakCount: data.streakCount))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let data = WidgetDataProvider.fetchData()
        let entry = StreakEntry(date: .now, streakCount: data.streakCount)

        // Refresh at midnight
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: .now)!)
        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }
}
