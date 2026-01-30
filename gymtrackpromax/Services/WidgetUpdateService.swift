//
//  WidgetUpdateService.swift
//  GymTrack Pro
//
//  Created by Claude Code on 30/01/26.
//

import WidgetKit

/// Service to trigger widget timeline refreshes from the main app.
enum WidgetUpdateService {

    /// Reloads all widget timelines. Call after workout completion or data changes.
    static func reloadAllTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Reloads a specific widget's timeline by its kind identifier.
    static func reloadTimeline(kind: String) {
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }
}
